import { describe, expect, it } from "vitest";
import { parseCaltransKml } from "../src/parsers/caltrans.js";

const SAMPLE_KML = `<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>EB I-80 Chain Control level R-2</name>
      <description>Chains required for all vehicles except 4WD.</description>
      <Point>
        <coordinates>-120.2000,39.3000,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>`;

describe("parseCaltransKml", () => {
  it("extracts highway, chain level, and coordinates", () => {
    const events = parseCaltransKml(SAMPLE_KML, "2024-01-01T00:00:00Z");
    expect(events).toHaveLength(1);

    const event = events[0];
    expect(event.highway).toBe("I-80");
    expect(event.chainLevel).toBe("R-2");
    expect(event.point).toEqual({ lat: 39.3, lon: -120.2 });
  });
});
