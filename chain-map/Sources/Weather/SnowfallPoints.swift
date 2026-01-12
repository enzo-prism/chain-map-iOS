import Foundation

struct SnowfallPoint: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let corridorId: String?
}

extension SnowfallPoint {
    static let defaultPoints: [SnowfallPoint] = [
        SnowfallPoint(
            id: "donner",
            name: "Donner Summit",
            latitude: 39.3206,
            longitude: -120.3327,
            corridorId: "i80-donner"
        ),
        SnowfallPoint(
            id: "echo",
            name: "Echo Summit",
            latitude: 38.8154,
            longitude: -120.0414,
            corridorId: "us50-echo"
        ),
        SnowfallPoint(
            id: "carson",
            name: "Carson Pass",
            latitude: 38.7056,
            longitude: -119.9880,
            corridorId: "ca88-carson"
        ),
        SnowfallPoint(
            id: "mt-rose",
            name: "Mt Rose / Reno",
            latitude: 39.3133,
            longitude: -119.8863,
            corridorId: nil
        )
    ]

    static func point(for corridorId: String) -> SnowfallPoint? {
        defaultPoints.first(where: { $0.corridorId == corridorId })
    }
}
