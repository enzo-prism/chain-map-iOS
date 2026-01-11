import Combine
import Foundation

@MainActor
final class CorridorsViewModel: ObservableObject {
    @Published var corridors: [CorridorSummary] = []
    @Published var lastUpdatedAt: Date?
    @Published var isStale = false
    @Published var lastErrorMessage: String?

    private let client: ChainMapAPIClient
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 90
    private static let dateParser = ISO8601DateFormatter()
    private var isRefreshing = false

    @MainActor
    init(client: ChainMapAPIClient = ChainMapAPIClient()) {
        self.client = client
    }

    func startPolling() {
        guard timer == nil else { return }
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

    private func refreshOnce() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let response = try await client.fetchCorridors()
            corridors = response.corridors
            lastUpdatedAt = Self.dateParser.date(from: response.generatedAt)
            isStale = false
            lastErrorMessage = nil
        } catch {
            isStale = true
            lastErrorMessage = "Unable to refresh"
        }
    }
}
