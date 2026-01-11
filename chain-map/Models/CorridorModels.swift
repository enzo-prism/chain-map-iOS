import Foundation

struct CorridorResponse: Codable {
    let generatedAt: String
    let corridors: [CorridorSummary]
}

struct CorridorSummary: Codable, Identifiable {
    let id: String
    let label: String
    let status: CorridorStatus
}

struct CorridorStatus: Codable {
    let severity: CorridorSeverity
    let headline: String
    let details: [String]
    let sources: [String]
    let lastUpdatedAt: String
}

enum CorridorSeverity: String, Codable {
    case ok
    case caution
    case chains
    case closed
    case unknown
}
