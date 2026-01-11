import { XMLParser } from "fast-xml-parser";
import { CALTRANS_KML_URL, SIERRA_BOUNDS } from "../config.js";
import {
  ChainLevel,
  NormalizedEvent,
  Point
} from "../types.js";
import {
  cleanText,
  isWithinBounds,
  parseFirstCoordinate,
  stableHash
} from "../utils.js";

const CALTRANS_HIGHWAYS = new Set([
  "I-80",
  "US-50",
  "CA-88",
  "CA-89",
  "CA-28",
  "CA-267"
]);

export async function fetchCaltransKml(): Promise<string> {
  const response = await fetch(CALTRANS_KML_URL, {
    headers: {
      "User-Agent": "chain-map-backend/0.1"
    }
  });

  if (!response.ok) {
    throw new Error(`Caltrans KML fetch failed: ${response.status}`);
  }

  return response.text();
}

export function parseCaltransKml(
  kml: string,
  generatedAt: string
): NormalizedEvent[] {
  const parser = new XMLParser({
    ignoreAttributes: false,
    allowBooleanAttributes: true
  });
  const parsed = parser.parse(kml);
  const placemarks = collectPlacemarks(parsed);

  return placemarks
    .map((placemark) => parsePlacemark(placemark, generatedAt))
    .filter((event): event is NormalizedEvent => Boolean(event))
    .filter((event) => {
      if (event.highway && CALTRANS_HIGHWAYS.has(event.highway)) {
        return true;
      }

      if (event.point) {
        return isWithinBounds(event.point, SIERRA_BOUNDS);
      }

      return false;
    });
}

function collectPlacemarks(node: unknown, acc: unknown[] = []): unknown[] {
  if (!node || typeof node !== "object") {
    return acc;
  }

  if (Array.isArray(node)) {
    node.forEach((child) => collectPlacemarks(child, acc));
    return acc;
  }

  const record = node as Record<string, unknown>;
  if (record.Placemark) {
    const placemark = record.Placemark;
    if (Array.isArray(placemark)) {
      placemark.forEach((item) => acc.push(item));
    } else {
      acc.push(placemark);
    }
  }

  Object.values(record).forEach((child) => collectPlacemarks(child, acc));
  return acc;
}

function parsePlacemark(
  placemark: Record<string, unknown>,
  generatedAt: string
): NormalizedEvent | null {
  const rawName = typeof placemark.name === "string" ? placemark.name : "";
  const rawDescription =
    typeof placemark.description === "string" ? placemark.description : "";

  const name = cleanText(rawName);
  const description = cleanText(rawDescription);
  const combined = `${name} ${description}`.trim();

  const coordinates = extractCoordinates(placemark);
  const point = parseFirstCoordinate(coordinates);

  const highway = extractHighway(combined);
  const direction = extractDirection(combined);
  const chainLevel = extractChainLevel(combined);

  if (!name && !description && !point) {
    return null;
  }

  const title = name || description || "Chain control";
  const statusText = description || name || "Chain control";

  const id = stableHash(
    JSON.stringify({
      source: "caltrans_quickmap",
      title,
      statusText,
      highway,
      direction,
      chainLevel,
      point
    })
  );

  return {
    id,
    source: "caltrans_quickmap",
    type: "chain_control",
    highway,
    direction,
    title,
    statusText,
    chainLevel,
    point,
    encodedPolyline: null,
    lastUpdatedAt: generatedAt
  };
}

function extractCoordinates(placemark: Record<string, unknown>): string | null {
  const point = placemark.Point as Record<string, unknown> | undefined;
  const lineString = placemark.LineString as Record<string, unknown> | undefined;

  const pointCoords =
    point && typeof point.coordinates === "string" ? point.coordinates : null;
  if (pointCoords) {
    return pointCoords;
  }

  const lineCoords =
    lineString && typeof lineString.coordinates === "string"
      ? lineString.coordinates
      : null;

  return lineCoords;
}

function extractDirection(text: string): string | null {
  const shortMatch = text.match(/\b(EB|WB|NB|SB)\b/i);
  if (shortMatch) {
    return shortMatch[1].toUpperCase();
  }

  const longMatch = text.match(
    /\b(EASTBOUND|WESTBOUND|NORTHBOUND|SOUTHBOUND)\b/i
  );
  if (!longMatch) {
    return null;
  }

  const normalized = longMatch[1].toUpperCase();
  if (normalized === "EASTBOUND") {
    return "EB";
  }
  if (normalized === "WESTBOUND") {
    return "WB";
  }
  if (normalized === "NORTHBOUND") {
    return "NB";
  }
  if (normalized === "SOUTHBOUND") {
    return "SB";
  }
  return null;
}

function extractHighway(text: string): string | null {
  const patterns: Array<{ regex: RegExp; value: string }> = [
    { regex: /\bI\s*-?\s*80\b/i, value: "I-80" },
    { regex: /\bU\.?\s*S\.?\s*-?\s*50\b/i, value: "US-50" },
    { regex: /\bU\.?\s*S\.?\s*-?\s*395\b/i, value: "US-395" },
    {
      regex: /\b(CA|SR|Hwy\.?|State Route)\s*-?\s*88\b/i,
      value: "CA-88"
    },
    {
      regex: /\b(CA|SR|Hwy\.?|State Route)\s*-?\s*89\b/i,
      value: "CA-89"
    },
    {
      regex: /\b(CA|SR|Hwy\.?|State Route)\s*-?\s*28\b/i,
      value: "CA-28"
    },
    {
      regex: /\b(CA|SR|Hwy\.?|State Route)\s*-?\s*267\b/i,
      value: "CA-267"
    }
  ];

  for (const pattern of patterns) {
    if (pattern.regex.test(text)) {
      return pattern.value;
    }
  }

  return null;
}

function extractChainLevel(text: string): ChainLevel {
  if (/\bNO\s+CHAIN\b/i.test(text) || /\bNO\s+RESTRICTIONS\b/i.test(text)) {
    return "R-0";
  }

  const match = text.match(/\bR\s*-?\s*([0-3])\b/i);
  if (match) {
    return `R-${match[1]}` as ChainLevel;
  }

  if (/\bR\s*\/?\s*C\b/i.test(text)) {
    return "RC";
  }

  if (/\bESC\b/i.test(text)) {
    return "ESC";
  }

  if (/\bHT\b/i.test(text)) {
    return "HT";
  }

  return "UNKNOWN";
}

export function parseCaltransChainLevel(text: string): ChainLevel {
  return extractChainLevel(text);
}

export function parseCaltransHighway(text: string): string | null {
  return extractHighway(text);
}

export function parseCaltransPoint(text: string): Point | null {
  return parseFirstCoordinate(text);
}
