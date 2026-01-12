import Foundation

enum CaltransCWWP2Error: Error {
    case invalidResponse
    case badStatus(Int)
    case invalidData
}

struct CaltransCWWP2Client {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchChainControls(from url: URL) async throws -> [CaltransChainControlRecord] {
        let data = try await fetchData(from: url)
        return try Self.decodeChainControls(from: data)
    }

    func fetchLaneClosures(from url: URL) async throws -> [CaltransLaneClosureRecord] {
        let data = try await fetchData(from: url)
        return try Self.decodeLaneClosures(from: data)
    }

    static func decodeChainControls(from data: Data) throws -> [CaltransChainControlRecord] {
        let decoded = try JSONDecoder().decode(CaltransChainControlResponse.self, from: data)
        return decoded.data.compactMap { $0.cc }
    }

    static func decodeLaneClosures(from data: Data) throws -> [CaltransLaneClosureRecord] {
        let decoded = try JSONDecoder().decode(CaltransLaneClosureResponse.self, from: data)
        return decoded.data.compactMap { $0.lcs }
    }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CaltransCWWP2Error.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw CaltransCWWP2Error.badStatus(httpResponse.statusCode)
        }
        guard !data.isEmpty else {
            throw CaltransCWWP2Error.invalidData
        }
        return data
    }
}
