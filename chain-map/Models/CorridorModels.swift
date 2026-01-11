import Foundation

struct CorridorResponse: Decodable {
    let generatedAt: String
    let corridors: [CorridorSummary]
}

struct CorridorSummary: Decodable, Identifiable {
    let id: String
    let label: String
    let status: CorridorStatus
}

struct CorridorStatus: Decodable {
    let severity: CorridorSeverity
    let headline: String
    let details: [String]
    let sources: [String]
    let lastUpdatedAt: String
}

enum CorridorSeverity: String, Decodable {
    case ok
    case caution
    case chains
    case closed
    case unknown
}
