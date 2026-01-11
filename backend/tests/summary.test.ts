import { describe, expect, it } from "vitest";
import { summarizeCorridors } from "../src/summary.js";
import { NormalizedEvent } from "../src/types.js";

const generatedAt = "2024-01-01T00:00:00Z";

function makeEvent(overrides: Partial<NormalizedEvent>): NormalizedEvent {
  return {
    id: overrides.id ?? "event",
    source: overrides.source ?? "caltrans_quickmap",
    type: overrides.type ?? "chain_control",
    highway: overrides.highway ?? "I-80",
    direction: overrides.direction ?? null,
    title: overrides.title ?? "Chain Control level R-2",
    statusText: overrides.statusText ?? "Chain Control level R-2",
    chainLevel:
      overrides.chainLevel !== undefined ? overrides.chainLevel : "R-2",
    point: overrides.point ?? null,
    encodedPolyline: overrides.encodedPolyline ?? null,
    lastUpdatedAt: overrides.lastUpdatedAt ?? generatedAt
  };
}

describe("summarizeCorridors", () => {
  it("marks closed when a closure event is present", () => {
    const events = [
      makeEvent({
        highway: "US-50",
        chainLevel: "R-1",
        title: "Road closed for winter conditions",
        statusText: "Road closed at Echo Summit"
      })
    ];

    const summaries = summarizeCorridors(events, generatedAt);
    const us50 = summaries.find((corridor) => corridor.id === "us50-echo");

    expect(us50?.status.severity).toBe("closed");
    expect(us50?.status.headline).toContain("Closed");
  });

  it("prefers chains over caution and ok", () => {
    const events = [
      makeEvent({
        id: "caution",
        highway: "I-80",
        chainLevel: "R-1",
        title: "Chain Control level R-1",
        statusText: "Chains required for vehicles without snow tires"
      }),
      makeEvent({
        id: "chains",
        highway: "I-80",
        chainLevel: "R-2",
        title: "Chain Control level R-2",
        statusText: "Chains required"
      })
    ];

    const summaries = summarizeCorridors(events, generatedAt);
    const i80 = summaries.find((corridor) => corridor.id === "i80-donner");

    expect(i80?.status.severity).toBe("chains");
    expect(i80?.status.headline).toContain("R-2");
  });

  it("returns unknown when no events match a corridor", () => {
    const summaries = summarizeCorridors([], generatedAt);
    const ca88 = summaries.find((corridor) => corridor.id === "ca88-carson");

    expect(ca88?.status.severity).toBe("unknown");
    expect(ca88?.status.headline).toBe("No recent data");
  });

  it("treats caution keywords as caution", () => {
    const events = [
      makeEvent({
        id: "snow",
        highway: "NV-431",
        chainLevel: null,
        title: "Snowing near Mount Rose",
        statusText: "Reduced visibility due to snow"
      })
    ];

    const summaries = summarizeCorridors(events, generatedAt);
    const nv431 = summaries.find((corridor) => corridor.id === "nv431-mtrose");

    expect(nv431?.status.severity).toBe("caution");
    expect(nv431?.status.headline).toContain("Caution");
  });
});
