export type EventSource = "caltrans_quickmap" | "nevada_511";

export type ChainLevel =
  | "R-0"
  | "R-1"
  | "R-2"
  | "R-3"
  | "RC"
  | "ESC"
  | "HT"
  | "UNKNOWN"
  | null;

export type EventType = "chain_control" | "road_condition";

export type Severity = "ok" | "caution" | "chains" | "closed" | "unknown";

export interface Point {
  lat: number;
  lon: number;
}

export interface NormalizedEvent {
  id: string;
  source: EventSource;
  type: EventType;
  highway: string | null;
  direction: string | null;
  title: string;
  statusText: string;
  chainLevel: ChainLevel;
  point: Point | null;
  encodedPolyline: string | null;
  lastUpdatedAt: string;
}

export interface CorridorStatus {
  severity: Severity;
  headline: string;
  details: string[];
  sources: EventSource[];
  lastUpdatedAt: string;
}

export interface CorridorSummary {
  id: string;
  label: string;
  status: CorridorStatus;
}

export interface CacheFile {
  generatedAt: string;
  events: NormalizedEvent[];
}

export interface IngestState {
  lastNevadaAttemptAt: string | null;
  lastCaltransAttemptAt: string | null;
}
