import { CORRIDORS, corridorMatchesEvent } from "./corridors.js";
import { CorridorSummary, NormalizedEvent, Severity } from "./types.js";
import { unique } from "./utils.js";

export function summarizeCorridors(
  events: NormalizedEvent[],
  generatedAt: string
): CorridorSummary[] {
  return CORRIDORS.map((corridor) => {
    const corridorEvents = events.filter((event) =>
      corridorMatchesEvent(corridor, event)
    );

    return {
      id: corridor.id,
      label: corridor.label,
      status: buildStatus(corridorEvents, generatedAt)
    };
  });
}

function buildStatus(
  events: NormalizedEvent[],
  generatedAt: string
): CorridorSummary["status"] {
  if (events.length === 0) {
    return {
      severity: "unknown",
      headline: "No recent data",
      details: [],
      sources: [],
      lastUpdatedAt: generatedAt
    };
  }

  const sorted = [...events].sort((a, b) => {
    const severityDelta =
      severityRank(eventSeverity(b)) - severityRank(eventSeverity(a));
    if (severityDelta !== 0) {
      return severityDelta;
    }
    return b.lastUpdatedAt.localeCompare(a.lastUpdatedAt);
  });

  const headline = buildHeadline(sorted[0], eventSeverity(sorted[0]));
  const details = sorted.slice(0, 4).map((event) => formatDetail(event));
  const sources = unique(sorted.map((event) => event.source));
  const lastUpdatedAt = sorted.reduce((latest, event) =>
    event.lastUpdatedAt > latest ? event.lastUpdatedAt : latest
  , generatedAt);

  return {
    severity: eventSeverity(sorted[0]),
    headline,
    details,
    sources,
    lastUpdatedAt
  };
}

function eventSeverity(event: NormalizedEvent): Severity {
  const text = `${event.title} ${event.statusText}`.toLowerCase();

  if (/(closed|closure|road closed|all lanes closed|hold|escort)/i.test(text)) {
    return "closed";
  }

  if (
    event.chainLevel === "R-2" ||
    event.chainLevel === "R-3" ||
    event.chainLevel === "RC"
  ) {
    return "chains";
  }

  if (
    event.chainLevel === "R-1" ||
    /(caution|snow|icy|slippery|reduced visibility|winter driving|traction)/i.test(
      text
    )
  ) {
    return "caution";
  }

  if (
    /chains required/.test(text) ||
    /chain control\s*level\s*R-?2/i.test(text) ||
    /chain control\s*level\s*R-?3/i.test(text)
  ) {
    return "chains";
  }

  if (event.chainLevel === "R-0") {
    return "ok";
  }

  return "ok";
}

function severityRank(severity: Severity): number {
  switch (severity) {
    case "closed":
      return 4;
    case "chains":
      return 3;
    case "caution":
      return 2;
    case "ok":
      return 1;
    case "unknown":
    default:
      return 0;
  }
}

function buildHeadline(event: NormalizedEvent, severity: Severity): string {
  const route = event.highway ?? "Roadway";
  const direction = event.direction ? ` (${event.direction})` : "";

  if (severity === "closed") {
    return `Closed on ${route}${direction}`;
  }

  if (severity === "chains") {
    if (event.chainLevel && event.chainLevel !== "UNKNOWN") {
      return `Chains ${event.chainLevel} on ${route}${direction}`;
    }
    const routeLabel = `${route}${direction}`.trim();
    return `Chains Required (${routeLabel})`;
  }

  if (severity === "caution") {
    if (event.chainLevel === "R-1") {
      return `Chains R-1 on ${route}${direction}`;
    }
    return `Caution on ${route}${direction}`;
  }

  if (severity === "ok") {
    return "No chain restrictions reported";
  }

  return "No recent data";
}

function formatDetail(event: NormalizedEvent): string {
  const route = event.highway ?? "Roadway";
  const direction = event.direction ? ` ${event.direction}` : "";
  const status = event.statusText || event.title;

  return truncate(`${route}${direction}: ${status}`.trim(), 140);
}

function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) {
    return text;
  }
  return `${text.slice(0, maxLength - 3).trim()}...`;
}
