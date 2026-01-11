import { readCache, readIngestState, writeCache, writeIngestState } from "./cache.js";
import { NEVADA_MIN_INTERVAL_MS } from "./config.js";
import { fetchCaltransKml, parseCaltransKml } from "./parsers/caltrans.js";
import {
  fetchNevadaRoadConditions,
  normalizeNevadaRoadConditions
} from "./parsers/nevada.js";
import { CacheFile, NormalizedEvent } from "./types.js";

export interface IngestSummary {
  generatedAt: string;
  updatedSources: string[];
  skippedSources: string[];
  errors: string[];
  cache: CacheFile;
}

export async function runIngest(): Promise<IngestSummary> {
  const generatedAt = new Date().toISOString();
  const existingCache = await readCache();
  const existingEvents = existingCache?.events ?? [];
  const ingestState = await readIngestState();

  let events: NormalizedEvent[] = [...existingEvents];
  const updatedSources: string[] = [];
  const skippedSources: string[] = [];
  const errors: string[] = [];

  const caltransResult = await ingestCaltrans(generatedAt, ingestState, errors);
  if (caltransResult) {
    events = replaceSource(events, "caltrans_quickmap", caltransResult);
    updatedSources.push("caltrans_quickmap");
  }

  const nevadaResult = await ingestNevada(
    generatedAt,
    ingestState,
    errors,
    skippedSources
  );
  if (nevadaResult) {
    events = replaceSource(events, "nevada_511", nevadaResult);
    updatedSources.push("nevada_511");
  }

  await writeIngestState(ingestState);

  const shouldWriteCache = updatedSources.length > 0;
  const cache: CacheFile = shouldWriteCache
    ? {
        generatedAt,
        events
      }
    : existingCache ?? { generatedAt, events: [] };

  if (shouldWriteCache) {
    await writeCache(cache);
  }

  return {
    generatedAt: cache.generatedAt,
    updatedSources,
    skippedSources,
    errors,
    cache
  };
}

async function ingestCaltrans(
  generatedAt: string,
  ingestState: { lastCaltransAttemptAt: string | null },
  errors: string[]
): Promise<NormalizedEvent[] | null> {
  ingestState.lastCaltransAttemptAt = generatedAt;

  try {
    const kml = await fetchCaltransKml();
    return parseCaltransKml(kml, generatedAt);
  } catch (error) {
    errors.push(`caltrans_quickmap: ${String(error)}`);
    return null;
  }
}

async function ingestNevada(
  generatedAt: string,
  ingestState: { lastNevadaAttemptAt: string | null },
  errors: string[],
  skipped: string[]
): Promise<NormalizedEvent[] | null> {
  const lastAttempt = ingestState.lastNevadaAttemptAt
    ? Date.parse(ingestState.lastNevadaAttemptAt)
    : null;
  const now = Date.now();

  if (lastAttempt && now - lastAttempt < NEVADA_MIN_INTERVAL_MS) {
    skipped.push("nevada_511");
    return null;
  }

  ingestState.lastNevadaAttemptAt = generatedAt;

  try {
    const payload = await fetchNevadaRoadConditions();
    return normalizeNevadaRoadConditions(payload, generatedAt);
  } catch (error) {
    errors.push(`nevada_511: ${String(error)}`);
    return null;
  }
}

function replaceSource(
  events: NormalizedEvent[],
  source: NormalizedEvent["source"],
  nextEvents: NormalizedEvent[]
): NormalizedEvent[] {
  const filtered = events.filter((event) => event.source !== source);
  return [...filtered, ...nextEvents];
}
