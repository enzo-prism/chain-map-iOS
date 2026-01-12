import Foundation
import XCTest
@testable import ChainMapCore

final class CaltransCWWP2ParsingTests: XCTestCase {
    func testChainControlDecoding() throws {
        let data = try loadFixture(named: "caltrans_cc_sample.json")
        let records = try CaltransCWWP2Client.decodeChainControls(from: data)
        let record = try XCTUnwrap(records.first)

        XCTAssertEqual(record.route, "I-80")
        XCTAssertEqual(record.status, "R-2")
        XCTAssertEqual(record.direction, "EB")
        XCTAssertEqual(record.latitude ?? 0, 39.322, accuracy: 0.001)
        XCTAssertEqual(record.longitude ?? 0, -120.333, accuracy: 0.001)
    }

    func testLaneClosureDecoding() throws {
        let data = try loadFixture(named: "caltrans_lcs_sample.json")
        let records = try CaltransCWWP2Client.decodeLaneClosures(from: data)
        let record = try XCTUnwrap(records.first)

        XCTAssertEqual(record.beginRoute, "US-50")
        XCTAssertEqual(record.endRoute, "US-50")
        XCTAssertEqual(record.travelFlowDirection, "WB")
        XCTAssertEqual(record.lanesClosed, 1)
        XCTAssertEqual(record.totalExistingLanes, 2)
        XCTAssertEqual(record.closureStartEpoch ?? 0, 1736520000, accuracy: 0.1)
        XCTAssertEqual(record.closureEndEpoch ?? 0, 1736523600, accuracy: 0.1)
    }

    private func loadFixture(named name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: nil))
        return try Data(contentsOf: url)
    }
}
