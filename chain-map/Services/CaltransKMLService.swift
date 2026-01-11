import Foundation

enum CaltransKMLError: Error {
    case invalidResponse
    case badStatus(Int)
    case invalidData
}

struct ChainControlEvent {
    let highway: String?
    let direction: String?
    let chainLevel: ChainLevel
    let title: String
    let statusText: String
}

enum ChainLevel: String {
    case r0 = "R-0"
    case r1 = "R-1"
    case r2 = "R-2"
    case r3 = "R-3"
    case rc = "RC"
    case esc = "ESC"
    case ht = "HT"
    case unknown = "UNKNOWN"
}

final class CaltransKMLService {
    private let session: URLSession
    private let cacheURL: URL
    private let kmlURL = URL(string: "https://quickmap.dot.ca.gov/data/cc.kml")!
    private let dateFormatter = ISO8601DateFormatter()

    init(session: URLSession = .shared) {
        self.session = session
        self.cacheURL = CaltransKMLService.defaultCacheURL()
    }

    func fetchSnapshot() async throws -> CorridorResponse {
        let (data, response) = try await session.data(from: kmlURL)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CaltransKMLError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw CaltransKMLError.badStatus(httpResponse.statusCode)
        }

        guard let kml = String(data: data, encoding: .utf8) else {
            throw CaltransKMLError.invalidData
        }

        let generatedAt = dateFormatter.string(from: Date())
        let snapshot = try await Task.detached(priority: .utility) {
            let events = Self.parseEvents(from: kml)
            let corridors = Self.summarize(events: events, generatedAt: generatedAt)
            return CorridorResponse(generatedAt: generatedAt, corridors: corridors)
        }.value

        save(snapshot: snapshot)
        return snapshot
    }

    func loadCachedSnapshot() -> CorridorResponse? {
        guard let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }

        return try? JSONDecoder().decode(CorridorResponse.self, from: data)
    }

    private func save(snapshot: CorridorResponse) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        try? data.write(to: cacheURL, options: [.atomic])
    }

    private static func defaultCacheURL() -> URL {
        let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (baseURL ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("caltrans_chain_controls.json")
    }

    private static func parseEvents(from kml: String) -> [ChainControlEvent] {
        let parser = XMLParser(data: Data(kml.utf8))
        let delegate = CaltransKMLParser()
        parser.delegate = delegate
        parser.parse()

        return delegate.placemarks.compactMap { placemark in
            let combined = cleanText("\(placemark.name) \(placemark.description)")
            let highway = extractHighway(from: combined)
            guard highway != nil else {
                return nil
            }

            let title = cleanText(placemark.name)
            let statusText = cleanText(placemark.description)
            return ChainControlEvent(
                highway: highway,
                direction: extractDirection(from: combined),
                chainLevel: extractChainLevel(from: combined),
                title: title.isEmpty ? statusText : title,
                statusText: statusText.isEmpty ? title : statusText
            )
        }
    }

    private static func summarize(events: [ChainControlEvent], generatedAt: String) -> [CorridorSummary] {
        CorridorDefinition.all.map { corridor in
            let corridorEvents = events.filter { $0.highway == corridor.highway }
            let status = buildStatus(events: corridorEvents, generatedAt: generatedAt)
            return CorridorSummary(id: corridor.id, label: corridor.label, status: status)
        }
    }

    private static func buildStatus(events: [ChainControlEvent], generatedAt: String) -> CorridorStatus {
        guard !events.isEmpty else {
            return CorridorStatus(
                severity: .unknown,
                headline: "No recent data",
                details: [],
                sources: ["caltrans_quickmap"],
                lastUpdatedAt: generatedAt
            )
        }

        let sorted = events.sorted { left, right in
            severityRank(eventSeverity(left)) > severityRank(eventSeverity(right))
        }

        let headline = buildHeadline(from: sorted[0])
        let details = sorted.prefix(4).map { formatDetail($0) }

        return CorridorStatus(
            severity: eventSeverity(sorted[0]),
            headline: headline,
            details: details,
            sources: ["caltrans_quickmap"],
            lastUpdatedAt: generatedAt
        )
    }

    private static func eventSeverity(_ event: ChainControlEvent) -> CorridorSeverity {
        let text = "\(event.title) \(event.statusText)".lowercased()

        if text.contains("closed") || text.contains("closure") || text.contains("hold") || text.contains("escort") {
            return .closed
        }

        if event.chainLevel == .r2 || event.chainLevel == .r3 || event.chainLevel == .rc {
            return .chains
        }

        if event.chainLevel == .r1 || text.contains("caution") || text.contains("snow") || text.contains("icy") || text.contains("slippery") {
            return .caution
        }

        if event.chainLevel == .r0 {
            return .ok
        }

        return .unknown
    }

    private static func severityRank(_ severity: CorridorSeverity) -> Int {
        switch severity {
        case .closed:
            return 4
        case .chains:
            return 3
        case .caution:
            return 2
        case .ok:
            return 1
        case .unknown:
            return 0
        }
    }

    private static func buildHeadline(from event: ChainControlEvent) -> String {
        let route = event.highway ?? "Roadway"
        let direction = event.direction.map { " (\($0))" } ?? ""

        switch eventSeverity(event) {
        case .closed:
            return "Closed on \(route)\(direction)"
        case .chains:
            if event.chainLevel != .unknown {
                return "Chains \(event.chainLevel.rawValue) on \(route)\(direction)"
            }
            return "Chains Required on \(route)\(direction)"
        case .caution:
            if event.chainLevel == .r1 {
                return "Chains R-1 on \(route)\(direction)"
            }
            return "Caution on \(route)\(direction)"
        case .ok:
            return "No chain restrictions reported"
        case .unknown:
            return "No recent data"
        }
    }

    private static func formatDetail(_ event: ChainControlEvent) -> String {
        let route = event.highway ?? "Roadway"
        let direction = event.direction.map { " \($0)" } ?? ""
        let status = event.statusText.isEmpty ? event.title : event.statusText
        return truncate("\(route)\(direction): \(status)", maxLength: 140)
    }

    private static func truncate(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        let index = text.index(text.startIndex, offsetBy: maxLength - 3)
        return String(text[..<index]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private static func cleanText(_ input: String) -> String {
        let withoutTags = input.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let withoutEntities = withoutTags
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        return withoutEntities.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractDirection(from text: String) -> String? {
        let shortMatch = match(text, pattern: "\\b(EB|WB|NB|SB)\\b")
        if let shortMatch {
            return shortMatch.uppercased()
        }

        if text.range(of: "EASTBOUND", options: .caseInsensitive) != nil { return "EB" }
        if text.range(of: "WESTBOUND", options: .caseInsensitive) != nil { return "WB" }
        if text.range(of: "NORTHBOUND", options: .caseInsensitive) != nil { return "NB" }
        if text.range(of: "SOUTHBOUND", options: .caseInsensitive) != nil { return "SB" }
        return nil
    }

    private static func extractHighway(from text: String) -> String? {
        let patterns: [(String, String)] = [
            ("\\bI\\s*-?\\s*80\\b", "I-80"),
            ("\\bU\\.?\\s*S\\.?\\s*-?\\s*50\\b", "US-50"),
            ("\\b(CA|SR|Hwy\\.?|State Route)\\s*-?\\s*88\\b", "CA-88"),
            ("\\b(CA|SR|Hwy\\.?|State Route)\\s*-?\\s*89\\b", "CA-89"),
            ("\\b(CA|SR|Hwy\\.?|State Route)\\s*-?\\s*28\\b", "CA-28"),
            ("\\b(CA|SR|Hwy\\.?|State Route)\\s*-?\\s*267\\b", "CA-267")
        ]

        for (pattern, value) in patterns {
            if match(text, pattern: pattern) != nil {
                return value
            }
        }

        return nil
    }

    private static func extractChainLevel(from text: String) -> ChainLevel {
        if text.range(of: "NO CHAIN", options: .caseInsensitive) != nil ||
            text.range(of: "NO RESTRICTIONS", options: .caseInsensitive) != nil {
            return .r0
        }

        if let value = match(text, pattern: "\\bR\\s*-?\\s*([0-3])\\b") {
            switch value {
            case "0": return .r0
            case "1": return .r1
            case "2": return .r2
            case "3": return .r3
            default: break
            }
        }

        if text.range(of: "\\bR\\s*\\/?\\s*C\\b", options: [.regularExpression, .caseInsensitive]) != nil {
            return .rc
        }

        if text.range(of: "\\bESC\\b", options: [.regularExpression, .caseInsensitive]) != nil {
            return .esc
        }

        if text.range(of: "\\bHT\\b", options: [.regularExpression, .caseInsensitive]) != nil {
            return .ht
        }

        return .unknown
    }

    private static func match(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        if match.numberOfRanges > 1, let groupRange = Range(match.range(at: 1), in: text) {
            return String(text[groupRange])
        }

        if let fullRange = Range(match.range(at: 0), in: text) {
            return String(text[fullRange])
        }

        return nil
    }
}

private final class CaltransKMLParser: NSObject, XMLParserDelegate {
    struct Placemark {
        var name = ""
        var description = ""
        var coordinates = ""
    }

    private(set) var placemarks: [Placemark] = []
    private var currentPlacemark: Placemark?
    private var currentElement = ""
    private var buffer = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Placemark" {
            currentPlacemark = Placemark()
        }

        if elementName == "name" || elementName == "description" || elementName == "coordinates" {
            currentElement = elementName
            buffer = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard !currentElement.isEmpty else { return }
        buffer.append(string)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard var placemark = currentPlacemark else { return }

        if elementName == "Placemark" {
            placemarks.append(placemark)
            currentPlacemark = nil
            return
        }

        if elementName == "name" {
            placemark.name = buffer
        } else if elementName == "description" {
            placemark.description = buffer
        } else if elementName == "coordinates", placemark.coordinates.isEmpty {
            placemark.coordinates = buffer
        }

        if elementName == currentElement {
            currentElement = ""
            buffer = ""
        }

        currentPlacemark = placemark
    }
}
