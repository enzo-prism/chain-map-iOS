import Foundation

enum Nevada511Error: Error {
    case invalidResponse
    case badStatus(Int)
    case invalidData
}

struct Nevada511Event: Equatable {
    let id: String
    let route: String?
    let title: String
    let statusText: String
    let lastUpdatedAt: Date?
}

struct Nevada511Client {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchRoadConditions() async throws -> [Nevada511Event] {
        let url = baseURL.appendingPathComponent("roadconditions")
        let data = try await fetchData(from: url)
        return parseEvents(from: data)
    }

    func fetchEvents() async throws -> [Nevada511Event] {
        let url = baseURL.appendingPathComponent("events")
        let data = try await fetchData(from: url)
        return parseEvents(from: data)
    }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Nevada511Error.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw Nevada511Error.badStatus(httpResponse.statusCode)
        }
        guard !data.isEmpty else {
            throw Nevada511Error.invalidData
        }
        return data
    }

    private func parseEvents(from data: Data) -> [Nevada511Event] {
        guard let payload = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }

        let items = extractItems(from: payload)
        return items.compactMap { parseEvent(from: $0) }
    }

    private func extractItems(from payload: Any) -> [[String: Any]] {
        if let array = payload as? [[String: Any]] {
            return array
        }

        if let dict = payload as? [String: Any] {
            let possible = dict["RoadConditions"] ?? dict["roadConditions"] ?? dict["roadconditions"] ?? dict["data"] ?? dict["result"] ?? dict["items"]
            if let array = possible as? [[String: Any]] {
                return array
            }
        }

        return []
    }

    private func parseEvent(from item: [String: Any]) -> Nevada511Event? {
        let roadway = stringValue(for: ["RoadwayName", "roadwayName", "Roadway", "roadway"], in: item)
        let location = stringValue(for: ["LocationDescription", "locationDescription", "Location", "location"], in: item)
        let overallStatus = stringValue(for: ["OverallStatus", "overallStatus", "Status", "status"], in: item)
        let lastUpdated = numberValue(for: ["LastUpdated", "lastUpdated"], in: item)

        let combined = [roadway, location, overallStatus].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !combined.isEmpty else { return nil }

        let route = LiveDataParsing.normalizeRoute(combined)
        let title = [roadway, location].filter { !$0.isEmpty }.joined(separator: " - ")
        let statusText = overallStatus.isEmpty ? title : overallStatus
        let lastUpdatedAt = LiveDataParsing.parseEpoch(lastUpdated)

        let id = UUID().uuidString
        return Nevada511Event(
            id: id,
            route: route,
            title: title.isEmpty ? combined : title,
            statusText: statusText.isEmpty ? combined : statusText,
            lastUpdatedAt: lastUpdatedAt
        )
    }

    private func stringValue(for keys: [String], in item: [String: Any]) -> String {
        for key in keys {
            if let value = item[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty, trimmed.caseInsensitiveCompare("Not Reported") != .orderedSame {
                    return trimmed
                }
            }
        }
        return ""
    }

    private func numberValue(for keys: [String], in item: [String: Any]) -> Double? {
        for key in keys {
            if let value = item[key] as? Double {
                return value
            }
            if let value = item[key] as? Int {
                return Double(value)
            }
            if let value = item[key] as? String, let parsed = Double(value) {
                return parsed
            }
        }
        return nil
    }
}
