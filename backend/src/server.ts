import Fastify from "fastify";
import { readCache } from "./cache.js";
import { ALLOWED_INGEST_TOKEN, PORT } from "./config.js";
import { CORRIDORS, corridorMatchesEvent, findCorridorById } from "./corridors.js";
import { runIngest } from "./ingest.js";
import { summarizeCorridors } from "./summary.js";

const app = Fastify({ logger: true });
let ingestInProgress = false;

app.get("/v1/health", async () => {
  const cache = await readCache();
  return {
    status: "ok",
    generatedAt: cache?.generatedAt ?? new Date().toISOString(),
    corridorCount: CORRIDORS.length
  };
});

app.get("/v1/corridors", async () => {
  const cache = await readCache();
  const generatedAt = cache?.generatedAt ?? new Date().toISOString();
  const events = cache?.events ?? [];

  return {
    generatedAt,
    corridors: summarizeCorridors(events, generatedAt)
  };
});

app.get("/v1/events", async (request, reply) => {
  const query = request.query as { corridor?: string };
  if (!query.corridor) {
    return reply.code(400).send({ error: "corridor query param is required" });
  }

  const corridor = findCorridorById(query.corridor);
  if (!corridor) {
    return reply.code(404).send({ error: "corridor not found" });
  }

  const cache = await readCache();
  const generatedAt = cache?.generatedAt ?? new Date().toISOString();
  const events = (cache?.events ?? []).filter((event) =>
    corridorMatchesEvent(corridor, event)
  );

  return {
    generatedAt,
    corridor: corridor.id,
    events
  };
});

app.post("/v1/ingest", async (request, reply) => {
  const authHeader = request.headers.authorization ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();

  if (!ALLOWED_INGEST_TOKEN || token !== ALLOWED_INGEST_TOKEN) {
    return reply.code(401).send({ error: "unauthorized" });
  }

  if (ingestInProgress) {
    return reply.code(409).send({ error: "ingest already running" });
  }

  ingestInProgress = true;
  try {
    const result = await runIngest();
    return {
      generatedAt: result.generatedAt,
      updatedSources: result.updatedSources,
      skippedSources: result.skippedSources,
      errors: result.errors
    };
  } finally {
    ingestInProgress = false;
  }
});

app.listen({ port: PORT, host: "0.0.0.0" }).catch((error) => {
  app.log.error(error);
  process.exit(1);
});
