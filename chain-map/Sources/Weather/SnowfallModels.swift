import Foundation

struct SnowfallDay: Identifiable, Codable {
    let date: Date
    let snowfallInches: Double

    var id: Date { date }
}

struct SnowfallHistory: Codable {
    let pointId: String
    let pointName: String
    let days: [SnowfallDay]
    let total7DaysInches: Double
    let updatedAt: Date
    let source: String
    var isStale: Bool
}
