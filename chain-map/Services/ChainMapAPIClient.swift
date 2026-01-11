import Foundation

enum ChainMapAPIError: Error {
    case invalidResponse
    case badStatus(Int)
}

struct ChainMapAPIClient {
    let baseURL: URL

    init(baseURL: URL = ChainMapAPIClient.defaultBaseURL()) {
        self.baseURL = baseURL
    }

    func fetchCorridors() async throws -> CorridorResponse {
        let url = baseURL.appendingPathComponent("v1/corridors")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChainMapAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ChainMapAPIError.badStatus(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(CorridorResponse.self, from: data)
    }

    private static func defaultBaseURL() -> URL {
        if let envValue = ProcessInfo.processInfo.environment["CHAINMAP_API_BASE_URL"],
           let envURL = URL(string: envValue) {
            return envURL
        }

        if let infoValue = Bundle.main.object(forInfoDictionaryKey: "ChainMapAPIBaseURL") as? String,
           let infoURL = URL(string: infoValue) {
            return infoURL
        }

        return URL(string: "http://localhost:8787")!
    }
}
