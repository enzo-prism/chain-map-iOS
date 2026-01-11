import crypto from "node:crypto";
import { Point } from "./types.js";

export function stripHtml(input: string): string {
  return input.replace(/<[^>]*>/g, " ");
}

export function decodeEntities(input: string): string {
  return input
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'");
}

export function cleanText(input: string): string {
  const withoutHtml = decodeEntities(stripHtml(input));
  return withoutHtml.replace(/\s+/g, " ").trim();
}

export function parseFirstCoordinate(coordinates: string | undefined): Point | null {
  if (!coordinates) {
    return null;
  }

  const first = coordinates.trim().split(/\s+/)[0];
  if (!first) {
    return null;
  }

  const [lonRaw, latRaw] = first.split(",");
  const lat = Number(latRaw);
  const lon = Number(lonRaw);
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return null;
  }

  return { lat, lon };
}

export function isWithinBounds(point: Point, bounds: {
  minLon: number;
  maxLon: number;
  minLat: number;
  maxLat: number;
}): boolean {
  return (
    point.lon >= bounds.minLon &&
    point.lon <= bounds.maxLon &&
    point.lat >= bounds.minLat &&
    point.lat <= bounds.maxLat
  );
}

export function unixToIso(value: unknown, fallbackIso: string): string {
  if (typeof value !== "number") {
    return fallbackIso;
  }

  const millis = value < 1_000_000_000_000 ? value * 1000 : value;
  const date = new Date(millis);
  if (Number.isNaN(date.getTime())) {
    return fallbackIso;
  }

  return date.toISOString();
}

export function stableHash(input: string): string {
  return crypto.createHash("sha1").update(input).digest("hex");
}

export function unique<T>(values: T[]): T[] {
  return Array.from(new Set(values));
}
