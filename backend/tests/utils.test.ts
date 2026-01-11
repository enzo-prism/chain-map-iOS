import { describe, expect, it } from "vitest";
import { cleanText, isWithinBounds, parseFirstCoordinate } from "../src/utils.js";

const bounds = {
  minLon: -123,
  maxLon: -118,
  minLat: 37,
  maxLat: 41
};

describe("parseFirstCoordinate", () => {
  it("parses lon/lat pairs", () => {
    const point = parseFirstCoordinate("-120.5,39.2,0 -121.0,39.0,0");
    expect(point).toEqual({ lat: 39.2, lon: -120.5 });
  });

  it("returns null when invalid", () => {
    expect(parseFirstCoordinate("invalid" as string)).toBeNull();
  });
});

describe("isWithinBounds", () => {
  it("detects points inside bounds", () => {
    const inside = { lat: 39.0, lon: -120.0 };
    expect(isWithinBounds(inside, bounds)).toBe(true);
  });

  it("detects points outside bounds", () => {
    const outside = { lat: 35.0, lon: -120.0 };
    expect(isWithinBounds(outside, bounds)).toBe(false);
  });
});

describe("cleanText", () => {
  it("removes html and normalizes whitespace", () => {
    const text = cleanText("<b>Chains</b> &amp; restrictions\n");
    expect(text).toBe("Chains & restrictions");
  });
});
