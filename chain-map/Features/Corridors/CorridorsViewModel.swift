import Combine
import Foundation

@MainActor
final class CorridorsViewModel: ObservableObject {
    @Published var corridors: [CorridorSummary] = []
    @Published var lastUpdatedAt: Date?
    @Published var isStale = false
    @Published var lastErrorMessage: String?

    private let service: CaltransKMLService
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 180
    private static let dateParser = ISO8601DateFormatter()
    private var isRefreshing = false
    private var hasLoadedCache = false

    @MainActor
    init(service: CaltransKMLService) {
        self.service = service
    }

    @MainActor
    convenience init() {
        self.init(service: CaltransKMLService())
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
        lastUpdatedAt = Self.dateParser.date(from: snapshot.generatedAt)
        self.isStale = isStale
        lastErrorMessage = nil
    }
}
