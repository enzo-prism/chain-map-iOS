import fs from "node:fs/promises";
import path from "node:path";
import { CACHE_FILE, INGEST_STATE_FILE } from "./config.js";
import { CacheFile, IngestState } from "./types.js";

async function ensureDir(filePath: string): Promise<void> {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
}

export async function readCache(): Promise<CacheFile | null> {
  try {
    const raw = await fs.readFile(CACHE_FILE, "utf8");
    const parsed = JSON.parse(raw) as CacheFile;
    if (!parsed || !Array.isArray(parsed.events)) {
      return null;
    }
    return parsed;
  } catch (error) {
    return null;
  }
}

export async function writeCache(cache: CacheFile): Promise<void> {
  await ensureDir(CACHE_FILE);
  await fs.writeFile(CACHE_FILE, JSON.stringify(cache, null, 2), "utf8");
}

export async function readIngestState(): Promise<IngestState> {
  try {
    const raw = await fs.readFile(INGEST_STATE_FILE, "utf8");
    const parsed = JSON.parse(raw) as IngestState;
    return {
      lastNevadaAttemptAt: parsed.lastNevadaAttemptAt ?? null,
      lastCaltransAttemptAt: parsed.lastCaltransAttemptAt ?? null
    };
  } catch (error) {
    return {
      lastNevadaAttemptAt: null,
      lastCaltransAttemptAt: null
    };
  }
}

export async function writeIngestState(state: IngestState): Promise<void> {
  await ensureDir(INGEST_STATE_FILE);
  await fs.writeFile(INGEST_STATE_FILE, JSON.stringify(state, null, 2), "utf8");
}
