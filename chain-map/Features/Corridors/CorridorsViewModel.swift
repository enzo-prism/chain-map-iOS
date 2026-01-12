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

    private let service: CorridorSnapshotService
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 60
    private static let dateParser = ISO8601DateFormatter()
    private var isRefreshing = false
    private var hasLoadedCache = false
    private let staleThreshold: TimeInterval = 600

    @MainActor
    init(service: CorridorSnapshotService) {
        self.service = service
    }

    @MainActor
    convenience init() {
        let configuration = LiveDataConfiguration.fromBundle()
        if configuration.useDotFeedsDirectly {
            self.init(service: DotFeedsService(nevadaProxyBaseURL: configuration.nevadaProxyBaseURL))
        } else {
            self.init(service: CaltransKMLService())
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
}
