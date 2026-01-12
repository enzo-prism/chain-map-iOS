import Foundation

final class DotFeedsService {
    private struct CaltransEndpoints {
        static let chainControls = [
            URL(string: "https://cwwp2.dot.ca.gov/data/d3/cc/ccStatusD03.json")!,
            URL(string: "https://cwwp2.dot.ca.gov/data/d10/cc/ccStatusD10.json")!
        ]
        static let laneClosures = [
            URL(string: "https://cwwp2.dot.ca.gov/data/d3/lcs/lcsStatusD03.json")!,
            URL(string: "https://cwwp2.dot.ca.gov/data/d10/lcs/lcsStatusD10.json")!
        ]
    }

    private let caltransClient: CaltransCWWP2Client
    private let nevadaClient: Nevada511Client?
    private let cacheURL: URL
    private var chainControls: [CaltransChainControlRecord] = []
    private var laneClosures: [CaltransLaneClosureRecord] = []
    private var nevadaEvents: [Nevada511Event] = []
    private var lastChainFetchAt: Date?
    private var lastLaneFetchAt: Date?
    private var lastSnapshot: CorridorResponse?
    private var lastGeneratedAt: Date?
    private let chainInterval: TimeInterval = 60
    private let laneInterval: TimeInterval = 300

    init(
        session: URLSession = .shared,
        cacheURL: URL? = nil,
        nevadaProxyBaseURL: URL? = nil
    ) {
        self.caltransClient = CaltransCWWP2Client(session: session)
        if let nevadaProxyBaseURL {
            self.nevadaClient = Nevada511Client(baseURL: nevadaProxyBaseURL, session: session)
        } else {
            self.nevadaClient = nil
        }
        self.cacheURL = cacheURL ?? DotFeedsService.defaultCacheURL()
    }

    func fetchSnapshot() async throws -> CorridorResponse {
        let now = Date()
        let shouldFetchChain = shouldFetch(lastFetchAt: lastChainFetchAt, interval: chainInterval, now: now)
        let shouldFetchLane = shouldFetch(lastFetchAt: lastLaneFetchAt, interval: laneInterval, now: now)

        if !shouldFetchChain, !shouldFetchLane, let snapshot = lastSnapshot {
            return snapshot
        }

        if shouldFetchChain {
            do {
                let records = try await fetchCaltransChainControls()
                chainControls = records
                lastChainFetchAt = now
            } catch {
                if chainControls.isEmpty {
                    throw error
                }
            }
        }

        if shouldFetchLane {
            do {
                let records = try await fetchCaltransLaneClosures()
                laneClosures = records
                lastLaneFetchAt = now
            } catch {
                if laneClosures.isEmpty {
                    throw error
                }
            }
        }

        if let nevadaClient, shouldFetchLane {
            do {
                async let roadConditions = nevadaClient.fetchRoadConditions()
                async let events = nevadaClient.fetchEvents()
                nevadaEvents = try await (roadConditions + events)
            } catch {
                if nevadaEvents.isEmpty {
                    nevadaEvents = []
                }
            }
        }

        let generatedAt = shouldFetchChain || shouldFetchLane ? now : (lastGeneratedAt ?? now)
        lastGeneratedAt = generatedAt

        let snapshot = buildSnapshot(
            chainControls: chainControls,
            laneClosures: laneClosures,
            nevadaEvents: nevadaEvents,
            generatedAt: generatedAt
        )
        lastSnapshot = snapshot
        save(snapshot: snapshot)
        return snapshot
    }

    func loadCachedSnapshot() -> CorridorResponse? {
        guard let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }

        return try? JSONDecoder().decode(CorridorResponse.self, from: data)
    }

    private func fetchCaltransChainControls() async throws -> [CaltransChainControlRecord] {
        async let d03 = caltransClient.fetchChainControls(from: CaltransEndpoints.chainControls[0])
        async let d10 = caltransClient.fetchChainControls(from: CaltransEndpoints.chainControls[1])
        let (records03, records10) = try await (d03, d10)
        return records03 + records10
    }

    private func fetchCaltransLaneClosures() async throws -> [CaltransLaneClosureRecord] {
        async let d03 = caltransClient.fetchLaneClosures(from: CaltransEndpoints.laneClosures[0])
        async let d10 = caltransClient.fetchLaneClosures(from: CaltransEndpoints.laneClosures[1])
        let (records03, records10) = try await (d03, d10)
        return records03 + records10
    }

    private func buildSnapshot(
        chainControls: [CaltransChainControlRecord],
        laneClosures: [CaltransLaneClosureRecord],
        nevadaEvents: [Nevada511Event],
        generatedAt: Date
    ) -> CorridorResponse {
        let corridors = CorridorDefinition.all.map { corridor in
            let matchingChain = chainControls.filter { matches(corridor: corridor, chainControl: $0) }
            let matchingClosures = laneClosures.filter { matches(corridor: corridor, laneClosure: $0) }
            let matchingNevada = nevadaEvents.filter { matches(corridor: corridor, nevadaEvent: $0) }
            let status = buildStatus(
                corridor: corridor,
                chainControls: matchingChain,
                laneClosures: matchingClosures,
                nevadaEvents: matchingNevada,
                generatedAt: generatedAt
            )
            return CorridorSummary(id: corridor.id, label: corridor.label, status: status)
        }

        return CorridorResponse(
            generatedAt: LiveDataParsing.isoFormatter.string(from: generatedAt),
            corridors: corridors
        )
    }

    private func matches(corridor: CorridorDefinition, chainControl: CaltransChainControlRecord) -> Bool {
        let candidates = [
            chainControl.route,
            chainControl.locationName,
            chainControl.nearbyPlace,
            chainControl.statusDescription
        ]
        for candidate in candidates where !candidate.isEmpty {
            if let route = LiveDataParsing.normalizeRoute(candidate), route == corridor.highway {
                return true
            }
        }
        return false
    }

    private func matches(corridor: CorridorDefinition, laneClosure: CaltransLaneClosureRecord) -> Bool {
        let candidates = [
            laneClosure.beginRoute,
            laneClosure.endRoute,
            laneClosure.beginLocationName,
            laneClosure.endLocationName,
            laneClosure.beginNearbyPlace,
            laneClosure.endNearbyPlace
        ]
        for candidate in candidates where !candidate.isEmpty {
            if let route = LiveDataParsing.normalizeRoute(candidate), route == corridor.highway {
                return true
            }
        }
        return false
    }

    private func matches(corridor: CorridorDefinition, nevadaEvent: Nevada511Event) -> Bool {
        guard let route = nevadaEvent.route else { return false }
        return route == corridor.highway
    }

    private func buildStatus(
        corridor: CorridorDefinition,
        chainControls: [CaltransChainControlRecord],
        laneClosures: [CaltransLaneClosureRecord],
        nevadaEvents: [Nevada511Event],
        generatedAt: Date
    ) -> CorridorStatus {
        let activeClosures = laneClosures.filter { isActive($0, at: generatedAt) }
        let normalizedChainStatuses = chainControls.map { LiveDataParsing.normalizeChainStatus($0.status) }
        let closedClosures = activeClosures.filter { isFullClosure($0) }
        let hasFullClosure = !closedClosures.isEmpty
        let hasChainR2Plus = normalizedChainStatuses.contains { ["R-2", "R-3", "RC"].contains($0) }
        let hasChainR1 = normalizedChainStatuses.contains("R-1")
        let hasLaneClosures = activeClosures.contains { (lanesClosed(for: $0) ?? 0) > 0 }
        let hasOnlyR0 = !normalizedChainStatuses.isEmpty && normalizedChainStatuses.allSatisfy { $0 == "R-0" }
        let hasNevadaClosed = nevadaEvents.contains { isClosedEvent($0) }
        let hasNevadaEvents = !nevadaEvents.isEmpty

        let severity: CorridorSeverity
        if hasFullClosure || hasNevadaClosed {
            severity = .closed
        } else if hasChainR2Plus {
            severity = .chains
        } else if hasChainR1 || hasLaneClosures || hasNevadaEvents {
            severity = .caution
        } else if hasOnlyR0 && !hasLaneClosures {
            severity = .ok
        } else if chainControls.isEmpty && laneClosures.isEmpty && nevadaEvents.isEmpty {
            severity = .unknown
        } else {
            severity = .unknown
        }

        let headline = buildHeadline(
            corridor: corridor,
            severity: severity,
            chainControls: chainControls,
            closures: activeClosures,
            nevadaEvents: nevadaEvents
        )

        let details = buildDetails(
            corridor: corridor,
            severity: severity,
            chainControls: chainControls,
            closures: activeClosures,
            nevadaEvents: nevadaEvents
        )

        let lastUpdated = latestUpdateDate(
            chainControls: chainControls,
            closures: activeClosures,
            nevadaEvents: nevadaEvents,
            fallback: generatedAt
        )

        let sources = buildSources(
            chainControls: chainControls,
            closures: activeClosures,
            nevadaEvents: nevadaEvents
        )

        return CorridorStatus(
            severity: severity,
            headline: headline,
            details: details,
            sources: sources,
            lastUpdatedAt: LiveDataParsing.isoFormatter.string(from: lastUpdated)
        )
    }

    private func buildHeadline(
        corridor: CorridorDefinition,
        severity: CorridorSeverity,
        chainControls: [CaltransChainControlRecord],
        closures: [CaltransLaneClosureRecord],
        nevadaEvents: [Nevada511Event]
    ) -> String {
        let route = corridor.highway

        switch severity {
        case .closed:
            if let closure = closures.first(where: { isFullClosure($0) }) {
                let direction = LiveDataParsing.normalizeDirection(closure.travelFlowDirection)
                let suffix = direction.map { " (\($0))" } ?? ""
                return "Road closed on \(route)\(suffix)"
            }
            if nevadaEvents.contains(where: { isClosedEvent($0) }) {
                return "Road closed on \(route)"
            }
            return "Road closed on \(route)"
        case .chains:
            if let record = chainControls.sorted(by: { chainSeverityRank($0) > chainSeverityRank($1) }).first {
                let status = LiveDataParsing.normalizeChainStatus(record.status)
                let direction = LiveDataParsing.normalizeDirection(record.direction)
                let suffix = direction.map { " (\($0))" } ?? ""
                return "\(status) chains on \(route)\(suffix)"
            }
            return "Chains required on \(route)"
        case .caution:
            if let record = chainControls.first(where: { LiveDataParsing.normalizeChainStatus($0.status) == "R-1" }) {
                let direction = LiveDataParsing.normalizeDirection(record.direction)
                let suffix = direction.map { " (\($0))" } ?? ""
                return "R-1 chains on \(route)\(suffix)"
            }
            if !closures.isEmpty {
                return "Lane closure on \(route)"
            }
            if !nevadaEvents.isEmpty {
                return "Road condition on \(route)"
            }
            return "Caution on \(route)"
        case .ok:
            return "Clear on \(route)"
        case .unknown:
            return "No recent data"
        }
    }

    private func buildDetails(
        corridor: CorridorDefinition,
        severity: CorridorSeverity,
        chainControls: [CaltransChainControlRecord],
        closures: [CaltransLaneClosureRecord],
        nevadaEvents: [Nevada511Event]
    ) -> [String] {
        var details: [String] = []

        let sortedChains = chainControls.sorted { chainSeverityRank($0) > chainSeverityRank($1) }
        for record in sortedChains {
            details.append(chainDetail(record, route: corridor.highway))
        }

        for closure in closures {
            details.append(closureDetail(closure, route: corridor.highway))
        }

        for event in nevadaEvents {
            details.append(nevadaDetail(event, route: corridor.highway))
        }

        if details.isEmpty, severity == .ok {
            details.append("No chain restrictions or closures reported.")
        }

        return Array(details.prefix(3))
    }

    private func chainDetail(_ record: CaltransChainControlRecord, route: String) -> String {
        let status = LiveDataParsing.normalizeChainStatus(record.status)
        let direction = LiveDataParsing.normalizeDirection(record.direction)
        let suffix = direction.map { " \($0)" } ?? ""
        let location = [record.locationName, record.nearbyPlace].first(where: { !$0.isEmpty }) ?? ""
        let description = record.statusDescription

        var detail = "\(status) on \(route)\(suffix)"
        if !location.isEmpty {
            detail += " - \(location)"
        }
        if !description.isEmpty, description.caseInsensitiveCompare(location) != .orderedSame {
            detail += " - \(description)"
        }
        return detail
    }

    private func closureDetail(_ record: CaltransLaneClosureRecord, route: String) -> String {
        let direction = LiveDataParsing.normalizeDirection(record.travelFlowDirection)
        let suffix = direction.map { " \($0)" } ?? ""
        let laneSummary = laneSummaryText(for: record)
        let work = record.typeOfWork

        var detail = "Closure on \(route)\(suffix)"
        if !laneSummary.isEmpty {
            detail += " - \(laneSummary)"
        }
        if !work.isEmpty {
            detail += " - \(work)"
        }
        return detail
    }

    private func nevadaDetail(_ event: Nevada511Event, route: String) -> String {
        let text = event.statusText.isEmpty ? event.title : event.statusText
        return "Nevada 511: \(route) - \(text)"
    }

    private func latestUpdateDate(
        chainControls: [CaltransChainControlRecord],
        closures: [CaltransLaneClosureRecord],
        nevadaEvents: [Nevada511Event],
        fallback: Date
    ) -> Date {
        var dates: [Date] = []
        for record in chainControls {
            if let date = LiveDataParsing.parseCaltransStatusDate(date: record.statusDate, time: record.statusTime) {
                dates.append(date)
            }
        }
        for closure in closures {
            if let start = LiveDataParsing.parseEpoch(closure.closureStartEpoch) {
                dates.append(start)
            } else if let end = LiveDataParsing.parseEpoch(closure.closureEndEpoch) {
                dates.append(end)
            }
        }
        for event in nevadaEvents {
            if let date = event.lastUpdatedAt {
                dates.append(date)
            }
        }

        return dates.max() ?? fallback
    }

    private func buildSources(
        chainControls: [CaltransChainControlRecord],
        closures: [CaltransLaneClosureRecord],
        nevadaEvents: [Nevada511Event]
    ) -> [String] {
        var sources: [String] = []
        if !chainControls.isEmpty {
            sources.append("caltrans_cwwp2_cc")
        }
        if !closures.isEmpty {
            sources.append("caltrans_cwwp2_lcs")
        }
        if !nevadaEvents.isEmpty {
            sources.append("nevada_511")
        }
        return sources
    }

    private func isActive(_ record: CaltransLaneClosureRecord, at date: Date) -> Bool {
        if let start = LiveDataParsing.parseEpoch(record.closureStartEpoch), date < start {
            return false
        }
        if let end = LiveDataParsing.parseEpoch(record.closureEndEpoch), date > end {
            return false
        }
        return true
    }

    private func isFullClosure(_ record: CaltransLaneClosureRecord) -> Bool {
        let type = record.typeOfClosure.lowercased()
        if type.contains("road") && type.contains("closure") {
            return true
        }
        if type.contains("full") || type.contains("total") || type.contains("complete") {
            return true
        }
        if let lanesClosed = lanesClosed(for: record),
           let total = record.totalExistingLanes,
           total > 0,
           lanesClosed >= total {
            return true
        }
        return false
    }

    private func isClosedEvent(_ event: Nevada511Event) -> Bool {
        let combined = "\(event.title) \(event.statusText)".lowercased()
        return combined.contains("closed") || combined.contains("closure")
    }

    private func lanesClosed(for record: CaltransLaneClosureRecord) -> Int? {
        record.lanesClosed
    }

    private func laneSummaryText(for record: CaltransLaneClosureRecord) -> String {
        if let closed = record.lanesClosed, let total = record.totalExistingLanes, total > 0 {
            return "\(closed) of \(total) lanes"
        }
        if let closed = record.lanesClosed {
            return "\(closed) lanes closed"
        }
        return record.typeOfClosure
    }

    private func chainSeverityRank(_ record: CaltransChainControlRecord) -> Int {
        switch LiveDataParsing.normalizeChainStatus(record.status) {
        case "R-3":
            return 4
        case "R-2":
            return 3
        case "RC":
            return 2
        case "R-1":
            return 1
        case "R-0":
            return 0
        default:
            return -1
        }
    }

    private func shouldFetch(lastFetchAt: Date?, interval: TimeInterval, now: Date) -> Bool {
        guard let lastFetchAt else { return true }
        return now.timeIntervalSince(lastFetchAt) >= interval
    }

    private func save(snapshot: CorridorResponse) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        let directory = cacheURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: [.atomic])
    }

    private static func defaultCacheURL() -> URL {
        let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (baseURL ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("dot_feeds_snapshot.json")
    }
}
