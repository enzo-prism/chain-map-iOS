import { config as loadEnv } from "dotenv";
import path from "node:path";

loadEnv({ path: path.join(process.cwd(), ".env") });

export const PORT = Number(process.env.PORT ?? "8787");
export const NEVADA_511_API_KEY = process.env.NEVADA_511_API_KEY ?? "";
export const ALLOWED_INGEST_TOKEN = process.env.ALLOWED_INGEST_TOKEN ?? "";

export const CALTRANS_KML_URL =
  "https://quickmap.dot.ca.gov/data/cc.kml";
export const NEVADA_511_URL =
  "https://www.nvroads.com/api/v2/get/roadconditions";

export const NEVADA_MIN_INTERVAL_MS = Number(
  process.env.NEVADA_MIN_INTERVAL_MS ?? "120000"
);

export const CACHE_FILE = path.join(
  process.cwd(),
  "data",
  "last_known_good.json"
);

export const INGEST_STATE_FILE = path.join(
  process.cwd(),
  "data",
  "ingest_state.json"
);

export const SIERRA_BOUNDS = {
  minLon: -123,
  maxLon: -118,
  minLat: 37,
  maxLat: 41
};
