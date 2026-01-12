import Combine
import Foundation

protocol CorridorSnapshotService {
    func fetchSnapshot() async throws -> CorridorResponse
    func loadCachedSnapshot() -> CorridorResponse?
}

extension CaltransKMLService: CorridorSnapshotService {}
extension DotFeedsService: CorridorSnapshotService {}

@MainActor
final class CorridorsViewModel: ObservableObject {
    @Published var corridors: [CorridorSummary] = []
    @Published var lastUpdatedAt: Date?
    @Published var isStale = false
    @Published var lastErrorMessage: String?
    @Published var snowfallByPointId: [String: SnowfallHistory] = [:]

    private let service: CorridorSnapshotService
    private let snowfallService: SnowfallService?
    private let snowfallPoints: [SnowfallPoint]
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 60
    private static let dateParser = ISO8601DateFormatter()
    private var isRefreshing = false
    private var hasLoadedCache = false
    private let staleThreshold: TimeInterval = 600

    @MainActor
    init(service: CorridorSnapshotService, snowfallService: SnowfallService?, snowfallPoints: [SnowfallPoint]) {
        self.service = service
        self.snowfallService = snowfallService
        self.snowfallPoints = snowfallPoints
    }

    @MainActor
    convenience init() {
        let configuration = LiveDataConfiguration.fromBundle()
        let snowfallConfiguration = SnowfallConfiguration.fromBundle()
        let snowfallService = snowfallConfiguration.isEnabled ? SnowfallService() : nil
        let snowfallPoints = SnowfallPoint.defaultPoints

        if configuration.useDotFeedsDirectly {
            self.init(
                service: DotFeedsService(nevadaProxyBaseURL: configuration.nevadaProxyBaseURL),
                snowfallService: snowfallService,
                snowfallPoints: snowfallPoints
            )
        } else {
            self.init(
                service: CaltransKMLService(),
                snowfallService: snowfallService,
                snowfallPoints: snowfallPoints
            )
        }
    }

    func startPolling() {
        guard timer == nil else { return }
        loadCacheIfNeeded()
        Task { await refreshOnce() }
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { await self?.refreshOnce() }
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func manualRefresh() {
        Task { await refreshOnce() }
    }

    private func loadCacheIfNeeded() {
        guard !hasLoadedCache else { return }
        hasLoadedCache = true

        if let snapshot = service.loadCachedSnapshot() {
            apply(snapshot: snapshot, isStale: true)
        }

        if let snowfallService {
            snowfallByPointId = snowfallService.cachedHistories()
        }
    }

    private func refreshOnce() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let snapshot = try await service.fetchSnapshot()
            apply(snapshot: snapshot, isStale: false)
        } catch {
            isStale = true
            lastErrorMessage = "Unable to refresh"
        }

        await refreshSnowfallIfNeeded()
    }

    private func apply(snapshot: CorridorResponse, isStale: Bool) {
        corridors = snapshot.corridors
        let corridorDates = snapshot.corridors.compactMap { Self.dateParser.date(from: $0.status.lastUpdatedAt) }
        let generatedAt = Self.dateParser.date(from: snapshot.generatedAt)
        let latest = corridorDates.max() ?? generatedAt
        lastUpdatedAt = latest

        if let latest {
            let age = Date().timeIntervalSince(latest)
            self.isStale = isStale || age > staleThreshold
        } else {
            self.isStale = true
        }
        lastErrorMessage = nil
    }

    private func refreshSnowfallIfNeeded() async {
        guard let snowfallService else { return }
        let updated = await snowfallService.refreshAllPointsIfNeeded(points: snowfallPoints)
        snowfallByPointId = updated
    }

    var isSnowfallEnabled: Bool {
        snowfallService != nil
    }

    var availableSnowfallPoints: [SnowfallPoint] {
        snowfallPoints
    }

    func snowfallPoint(for corridorId: String) -> SnowfallPoint? {
        SnowfallPoint.point(for: corridorId)
    }

    func snowfallHistory(for pointId: String) -> SnowfallHistory? {
        snowfallByPointId[pointId]
    }

    func snowfallSummaryText(for corridorId: String) -> String? {
        guard let point = snowfallPoint(for: corridorId) else {
            return nil
        }

        guard let history = snowfallByPointId[point.id], history.days.count == 7 else {
            return "Snow (7d): --"
        }

        return "Snow (7d): \(formatInches(history.total7DaysInches)) in"
    }

    func formatInches(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return String(format: "%.1f", rounded)
    }
}
