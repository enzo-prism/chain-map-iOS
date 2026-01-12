import Foundation

final class SnowfallService {
    private let client: OpenMeteoSnowfallClient
    private let cacheURL: URL
    private let refreshInterval: TimeInterval = 3 * 60 * 60
    private var lastRefreshAt: Date?
    private var histories: [String: SnowfallHistory] = [:]

    init(
        client: OpenMeteoSnowfallClient = OpenMeteoSnowfallClient(),
        cacheURL: URL? = nil
    ) {
        self.client = client
        self.cacheURL = cacheURL ?? SnowfallService.defaultCacheURL()
        loadCache()
    }

    func cachedHistories() -> [String: SnowfallHistory] {
        histories
    }

    func loadSnowfall7d(for point: SnowfallPoint) async -> SnowfallHistory {
        if let cached = histories[point.id] {
            return cached
        }

        do {
            let response = try await client.fetchSnowfallDaily(lat: point.latitude, lon: point.longitude)
            let history = Self.buildHistory(point: point, response: response, now: Date())
            histories[point.id] = history
            lastRefreshAt = Date()
            saveCache()
            return history
        } catch {
            let stale = Self.emptyHistory(point: point, updatedAt: Date.distantPast, isStale: true)
            return stale
        }
    }

    func refreshAllPointsIfNeeded(points: [SnowfallPoint]) async -> [String: SnowfallHistory] {
        let now = Date()
        if let lastRefreshAt, now.timeIntervalSince(lastRefreshAt) < refreshInterval {
            return histories
        }

        lastRefreshAt = now

        var updated = histories
        await withTaskGroup(of: (SnowfallPoint, Result<SnowfallHistory, Error>).self) { group in
            for point in points {
                group.addTask {
                    do {
                        let response = try await self.client.fetchSnowfallDaily(lat: point.latitude, lon: point.longitude)
                        let history = Self.buildHistory(point: point, response: response, now: now)
                        return (point, .success(history))
                    } catch {
                        return (point, .failure(error))
                    }
                }
            }

            for await result in group {
                switch result.1 {
                case .success(let history):
                    updated[result.0.id] = history
                case .failure:
                    if var existing = updated[result.0.id] {
                        existing.isStale = true
                        updated[result.0.id] = existing
                    }
                }
            }
        }

        histories = updated
        saveCache()
        return histories
    }

    static func buildHistory(
        point: SnowfallPoint,
        response: OpenMeteoSnowfallResponse,
        now: Date
    ) -> SnowfallHistory {
        let timezone = TimeZone(identifier: response.timezone ?? "") ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = timezone
        formatter.dateFormat = "yyyy-MM-dd"

        let unit = response.dailyUnits.snowfallSum
        let count = min(response.daily.time.count, response.daily.snowfallSum.count)
        var totalsByDay: [Date: Double] = [:]

        for index in 0..<count {
            let timeString = response.daily.time[index]
            guard let date = formatter.date(from: timeString) else { continue }
            let day = calendar.startOfDay(for: date)
            let rawValue = response.daily.snowfallSum[index] ?? 0
            let inches = convertToInches(rawValue, unit: unit)
            totalsByDay[day] = inches
        }

        let today = calendar.startOfDay(for: now)
        var days: [SnowfallDay] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let amount = totalsByDay[date] ?? 0
            days.append(SnowfallDay(date: date, snowfallInches: amount))
        }

        let total = days.reduce(0) { $0 + $1.snowfallInches }
        return SnowfallHistory(
            pointId: point.id,
            pointName: point.name,
            days: days,
            total7DaysInches: total,
            updatedAt: now,
            source: "open-meteo",
            isStale: false
        )
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let cache = try? Self.decoder.decode(SnowfallCache.self, from: data) else {
            return
        }

        lastRefreshAt = cache.lastRefreshAt
        let now = Date()
        histories = Dictionary(uniqueKeysWithValues: cache.histories.map { history in
            var updated = history
            if now.timeIntervalSince(history.updatedAt) > refreshInterval {
                updated.isStale = true
            }
            return (history.pointId, updated)
        })
    }

    private func saveCache() {
        let cache = SnowfallCache(
            lastRefreshAt: lastRefreshAt ?? Date(),
            histories: Array(histories.values)
        )
        guard let data = try? Self.encoder.encode(cache) else {
            return
        }

        let directory = cacheURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: [.atomic])
    }

    private static func convertToInches(_ value: Double, unit: String) -> Double {
        let normalized = unit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "cm":
            return value / 2.54
        case "mm":
            return value / 25.4
        case "inch", "in":
            return value
        default:
            return value
        }
    }

    private static func emptyHistory(point: SnowfallPoint, updatedAt: Date, isStale: Bool) -> SnowfallHistory {
        SnowfallHistory(
            pointId: point.id,
            pointName: point.name,
            days: [],
            total7DaysInches: 0,
            updatedAt: updatedAt,
            source: "open-meteo",
            isStale: isStale
        )
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private struct SnowfallCache: Codable {
        let lastRefreshAt: Date
        let histories: [SnowfallHistory]
    }

    private static func defaultCacheURL() -> URL {
        let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (baseURL ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("snowfall_history.json")
    }
}
