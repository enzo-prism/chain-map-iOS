import Foundation
import XCTest
@testable import ChainMapCore

final class CaltransKMLServiceTests: XCTestCase {
    func testSnapshotParsesChainLevels() async throws {
        let kml = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <kml xmlns=\"http://www.opengis.net/kml/2.2\">
          <Document>
            <Placemark>
              <name>EB I-80 Chain Control level R-2</name>
              <description>Chains required for all vehicles except 4WD.</description>
            </Placemark>
            <Placemark>
              <name>US-50 Chain Control level R-1</name>
              <description>Snowing near Echo Summit.</description>
            </Placemark>
          </Document>
        </kml>
        """

        let session = URLSession(configuration: URLSessionConfiguration.mock(data: Data(kml.utf8)))
        let cacheURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("cache.json")

        let service = CaltransKMLService(session: session, cacheURL: cacheURL)
        let snapshot = try await service.fetchSnapshot()

        let i80 = snapshot.corridors.first(where: { $0.id == "i80-donner" })
        let us50 = snapshot.corridors.first(where: { $0.id == "us50-echo" })

        XCTAssertEqual(i80?.status.severity, .chains)
        XCTAssertTrue(i80?.status.headline.contains("R-2") ?? false)

        XCTAssertEqual(us50?.status.severity, .caution)
        XCTAssertTrue(us50?.status.headline.contains("R-1") ?? false)
    }

    func testCachedSnapshotLoads() async throws {
        let kml = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <kml xmlns=\"http://www.opengis.net/kml/2.2\">
          <Document>
            <Placemark>
              <name>EB I-80 Chain Control level R-2</name>
              <description>Chains required</description>
            </Placemark>
          </Document>
        </kml>
        """

        let session = URLSession(configuration: URLSessionConfiguration.mock(data: Data(kml.utf8)))
        let cacheURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("cache.json")

        let service = CaltransKMLService(session: session, cacheURL: cacheURL)
        _ = try await service.fetchSnapshot()

        let cached = service.loadCachedSnapshot()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.corridors.count, CorridorDefinition.all.count)
    }
}

private final class URLProtocolStub: URLProtocol {
    static var responseData: Data?
    static var statusCode = 200

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://quickmap.dot.ca.gov")!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data = Self.responseData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private extension URLSessionConfiguration {
    static func mock(data: Data) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        URLProtocolStub.responseData = data
        URLProtocolStub.statusCode = 200
        configuration.protocolClasses = [URLProtocolStub.self]
        return configuration
    }
}
