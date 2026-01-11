import { describe, expect, it } from "vitest";
import { normalizeNevadaRoadConditions } from "../src/parsers/nevada.js";

const SAMPLE_PAYLOAD = {
  RoadConditions: [
    {
      RoadwayName: "NV-431 Mount Rose Highway",
      LocationDescription: "Summit to Incline Village",
      OverallStatus: "Chains Required",
      SecondaryConditions: ["Snowing"],
      EncodedPolyline: "abcd1234",
      LastUpdated: 1_700_000_000
    }
  ]
};

describe("normalizeNevadaRoadConditions", () => {
  it("extracts roadway status and last updated time", () => {
    const generatedAt = "2024-01-01T00:00:00Z";
    const events = normalizeNevadaRoadConditions(SAMPLE_PAYLOAD, generatedAt);

    expect(events).toHaveLength(1);
    const event = events[0];
    expect(event.highway).toBe("NV-431");
    expect(event.statusText).toContain("Chains Required");
    expect(event.lastUpdatedAt).toBe(
      new Date(1_700_000_000 * 1000).toISOString()
    );
  });
});
