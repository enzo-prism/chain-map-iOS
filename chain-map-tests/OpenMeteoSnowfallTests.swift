import Foundation
import XCTest
@testable import ChainMapCore

final class OpenMeteoSnowfallTests: XCTestCase {
    func testOpenMeteoDecoding() throws {
        let data = try loadFixture(named: "open_meteo_sample.json")
        let response = try JSONDecoder().decode(OpenMeteoSnowfallResponse.self, from: data)

        XCTAssertEqual(response.daily.time.count, 1)
        XCTAssertEqual(response.daily.snowfallSum.count, 1)
        XCTAssertEqual(response.dailyUnits.snowfallSum, "cm")
    }

    func testSelectionAndConversion() throws {
        let data = try loadFixture(named: "open_meteo_selection.json")
        let response = try JSONDecoder().decode(OpenMeteoSnowfallResponse.self, from: data)
        let point = SnowfallPoint(id: "donner", name: "Donner Summit", latitude: 0, longitude: 0, corridorId: nil)
        let now = ISO8601DateFormatter().date(from: "2026-01-10T12:00:00Z")!

        let history = SnowfallService.buildHistory(point: point, response: response, now: now)

        XCTAssertEqual(history.days.count, 7)
        XCTAssertEqual(formattedDate(history.days.first?.date), "2026-01-04")
        XCTAssertEqual(history.days.last?.snowfallInches ?? 0, 1.0, accuracy: 0.01)
    }

    private func loadFixture(named name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: nil))
        return try Data(contentsOf: url)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
