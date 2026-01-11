import { NEVADA_511_API_KEY, NEVADA_511_URL } from "../config.js";
import { NormalizedEvent } from "../types.js";
import { cleanText, stableHash, unixToIso } from "../utils.js";

const NEVADA_HIGHWAYS = new Set([
  "I-80",
  "US-395",
  "NV-431",
  "NV-28",
  "NV-267",
  "SR-207"
]);

export async function fetchNevadaRoadConditions(): Promise<unknown> {
  if (!NEVADA_511_API_KEY) {
    throw new Error("NEVADA_511_API_KEY is not set");
  }

  const url = new URL(NEVADA_511_URL);
  url.searchParams.set("key", NEVADA_511_API_KEY);
  url.searchParams.set("format", "json");

  const response = await fetch(url.toString(), {
    headers: {
      "User-Agent": "chain-map-backend/0.1"
    }
  });

  if (!response.ok) {
    throw new Error(`Nevada 511 fetch failed: ${response.status}`);
  }

  return response.json();
}

export function normalizeNevadaRoadConditions(
  payload: unknown,
  generatedAt: string
): NormalizedEvent[] {
  const items = extractItems(payload);

  return items
    .map((item) => normalizeItem(item, generatedAt))
    .filter((event): event is NormalizedEvent => Boolean(event))
    .filter((event) => isRelevantEvent(event));
}

function extractItems(payload: unknown): Array<Record<string, unknown>> {
  if (!payload) {
    return [];
  }

  if (Array.isArray(payload)) {
    return payload as Array<Record<string, unknown>>;
  }

  const record = payload as Record<string, unknown>;
  const possible =
    record.RoadConditions ??
    record.roadConditions ??
    record.roadconditions ??
    record.data ??
    record.result ??
    record.items;

  if (Array.isArray(possible)) {
    return possible as Array<Record<string, unknown>>;
  }

  return [];
}

function normalizeItem(
  item: Record<string, unknown>,
  generatedAt: string
): NormalizedEvent | null {
  const roadway = getString(item, [
    "RoadwayName",
    "roadwayName",
    "Roadway",
    "roadway"
  ]);
  const location = getString(item, [
    "LocationDescription",
    "locationDescription",
    "Location",
    "location"
  ]);
  const overallStatus = getString(item, [
    "OverallStatus",
    "overallStatus",
    "Status",
    "status"
  ]);
  const secondary = extractSecondaryConditions(item);
  const encodedPolyline = getString(item, [
    "EncodedPolyline",
    "encodedPolyline",
    "Polyline",
    "polyline"
  ]);
  const lastUpdated = getNumber(item, ["LastUpdated", "lastUpdated"]);

  const combined = cleanText(`${roadway} ${location} ${overallStatus}`);
  if (!combined) {
    return null;
  }

  const highway = extractHighway(combined);
  const title = cleanText(
    [roadway, location].filter(Boolean).join(" - ") || combined
  );
  const statusText = cleanText(
    [overallStatus, ...secondary].filter(Boolean).join("; ")
  );

  const id = stableHash(
    JSON.stringify({
      source: "nevada_511",
      roadway,
      location,
      overallStatus,
      secondary,
      encodedPolyline
    })
  );

  return {
    id,
    source: "nevada_511",
    type: "road_condition",
    highway,
    direction: null,
    title,
    statusText: statusText || title,
    chainLevel: null,
    point: null,
    encodedPolyline: encodedPolyline || null,
    lastUpdatedAt: unixToIso(lastUpdated, generatedAt)
  };
}

function extractSecondaryConditions(
  item: Record<string, unknown>
): string[] {
  const raw =
    item.SecondaryConditions ??
    item.secondaryConditions ??
    item.SecondaryCondition ??
    item.secondaryCondition;

  if (!raw) {
    return [];
  }

  if (Array.isArray(raw)) {
    return raw
      .map((entry) => {
        if (typeof entry === "string") {
          return entry;
        }
        if (entry && typeof entry === "object") {
          return String((entry as Record<string, unknown>).Condition ?? "");
        }
        return "";
      })
      .map((value) => cleanText(value))
      .filter(Boolean);
  }

  if (typeof raw === "string") {
    return [cleanText(raw)].filter(Boolean);
  }

  return [];
}

function extractHighway(text: string): string | null {
  const patterns: Array<{ regex: RegExp; value: string }> = [
    { regex: /\bI\s*-?\s*80\b/i, value: "I-80" },
    { regex: /\bU\.?\s*S\.?\s*-?\s*395\b/i, value: "US-395" },
    { regex: /\bNV\s*-?\s*431\b/i, value: "NV-431" },
    { regex: /\bSR\s*-?\s*431\b/i, value: "NV-431" },
    { regex: /\bNV\s*-?\s*28\b/i, value: "NV-28" },
    { regex: /\bSR\s*-?\s*28\b/i, value: "NV-28" },
    { regex: /\bNV\s*-?\s*267\b/i, value: "NV-267" },
    { regex: /\bSR\s*-?\s*267\b/i, value: "NV-267" },
    { regex: /\bSR\s*-?\s*207\b/i, value: "SR-207" },
    { regex: /\bNV\s*-?\s*207\b/i, value: "SR-207" }
  ];

  for (const pattern of patterns) {
    if (pattern.regex.test(text)) {
      return pattern.value;
    }
  }

  return null;
}

function isRelevantEvent(event: NormalizedEvent): boolean {
  if (event.highway && NEVADA_HIGHWAYS.has(event.highway)) {
    return true;
  }

  const text = `${event.title} ${event.statusText}`.toLowerCase();
  return [
    "tahoe",
    "reno",
    "incline",
    "carson",
    "truckee",
    "mt rose",
    "mount rose",
    "kingsbury"
  ].some((keyword) => text.includes(keyword));
}

function getString(
  item: Record<string, unknown>,
  keys: string[]
): string {
  for (const key of keys) {
    const value = item[key];
    if (typeof value === "string") {
      return value;
    }
  }

  return "";
}

function getNumber(
  item: Record<string, unknown>,
  keys: string[]
): number | null {
  for (const key of keys) {
    const value = item[key];
    if (typeof value === "number") {
      return value;
    }
    if (typeof value === "string") {
      const parsed = Number(value);
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }

  return null;
}
