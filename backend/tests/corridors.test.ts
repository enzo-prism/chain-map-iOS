import { describe, expect, it } from "vitest";
import {
  CORRIDORS,
  corridorMatchesEvent,
  findCorridorById
} from "../src/corridors.js";
import { NormalizedEvent } from "../src/types.js";

const sampleEvent: NormalizedEvent = {
  id: "event",
  source: "caltrans_quickmap",
  type: "chain_control",
  highway: "I-80",
  direction: "EB",
  title: "Chain Control level R-2",
  statusText: "Chains required",
  chainLevel: "R-2",
  point: null,
  encodedPolyline: null,
  lastUpdatedAt: "2024-01-01T00:00:00Z"
};

describe("corridorMatchesEvent", () => {
  it("matches by highway", () => {
    const corridor = findCorridorById("i80-donner");
    expect(corridor).toBeTruthy();
    expect(corridorMatchesEvent(corridor!, sampleEvent)).toBe(true);
  });

  it("matches by keyword when highway is missing", () => {
    const corridor = findCorridorById("nv431-mtrose");
    expect(corridor).toBeTruthy();

    const event = {
      ...sampleEvent,
      highway: null,
      title: "Mount Rose Highway",
      statusText: "Snowing near summit"
    };

    expect(corridorMatchesEvent(corridor!, event)).toBe(true);
  });

  it("does not match unrelated corridors", () => {
    const corridor = findCorridorById("ca88-carson");
    expect(corridor).toBeTruthy();
    expect(corridorMatchesEvent(corridor!, sampleEvent)).toBe(false);
  });
});

describe("corridors list", () => {
  it("has unique corridor ids", () => {
    const ids = CORRIDORS.map((corridor) => corridor.id);
    const uniqueIds = new Set(ids);
    expect(uniqueIds.size).toBe(ids.length);
  });
});
