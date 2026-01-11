import { NormalizedEvent } from "./types.js";

export interface CorridorDefinition {
  id: string;
  label: string;
  highways: string[];
  keywords: string[];
}

export const CORRIDORS: CorridorDefinition[] = [
  {
    id: "i80-donner",
    label: "I-80 (Donner Summit)",
    highways: ["I-80"],
    keywords: ["Donner", "Truckee", "Soda Springs"]
  },
  {
    id: "us50-echo",
    label: "US-50 (Echo Summit)",
    highways: ["US-50"],
    keywords: ["Echo Summit", "South Lake Tahoe", "Pollock"]
  },
  {
    id: "ca88-carson",
    label: "CA-88 (Carson Pass)",
    highways: ["CA-88"],
    keywords: ["Carson Pass", "Kirkwood"]
  },
  {
    id: "ca89-tahoe",
    label: "CA-89 (Tahoe Basin)",
    highways: ["CA-89"],
    keywords: ["Emerald Bay", "Tahoe", "Meeks"]
  },
  {
    id: "ca28-laketahoe",
    label: "CA-28 (Lake Tahoe)",
    highways: ["CA-28"],
    keywords: ["Tahoe City", "Kings Beach", "Crystal Bay"]
  },
  {
    id: "ca267-kings",
    label: "CA-267 (Truckee to Kings Beach)",
    highways: ["CA-267"],
    keywords: ["Kings Beach", "Northstar", "Brockway"]
  },
  {
    id: "nv431-mtrose",
    label: "NV-431 (Mt Rose Hwy)",
    highways: ["NV-431"],
    keywords: ["Mt Rose", "Mount Rose"]
  },
  {
    id: "us395-reno",
    label: "US-395 (Reno/Sierra)",
    highways: ["US-395"],
    keywords: ["Reno", "Carson", "Gardnerville"]
  },
  {
    id: "nv28-laketahoe",
    label: "NV-28 (Lake Tahoe)",
    highways: ["NV-28"],
    keywords: ["Incline", "Crystal Bay", "Sand Harbor"]
  },
  {
    id: "nv267-brockway",
    label: "NV-267 (Brockway Summit)",
    highways: ["NV-267"],
    keywords: ["Brockway"]
  },
  {
    id: "sr207-kingsbury",
    label: "SR-207 (Kingsbury Grade)",
    highways: ["SR-207"],
    keywords: ["Kingsbury", "Daggett"]
  }
];

export function corridorMatchesEvent(
  corridor: CorridorDefinition,
  event: NormalizedEvent
): boolean {
  if (event.highway) {
    const normalized = event.highway.toUpperCase();
    if (corridor.highways.some((highway) => highway === normalized)) {
      return true;
    }
  }

  const text = `${event.title} ${event.statusText}`.toLowerCase();
  return corridor.keywords.some((keyword) =>
    text.includes(keyword.toLowerCase())
  );
}

export function findCorridorById(id: string): CorridorDefinition | undefined {
  return CORRIDORS.find((corridor) => corridor.id === id);
}
