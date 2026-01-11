import CoreLocation

struct CorridorDefinition: Identifiable {
    let id: String
    let label: String
    let shortLabel: String
    let coordinate: CLLocationCoordinate2D
    let highway: String
}

extension CorridorDefinition {
    static let all: [CorridorDefinition] = [
        CorridorDefinition(
            id: "i80-donner",
            label: "I-80 (Donner Summit)",
            shortLabel: "I-80",
            coordinate: CLLocationCoordinate2D(latitude: 39.3206, longitude: -120.3327),
            highway: "I-80"
        ),
        CorridorDefinition(
            id: "us50-echo",
            label: "US-50 (Echo Summit)",
            shortLabel: "US-50",
            coordinate: CLLocationCoordinate2D(latitude: 38.8154, longitude: -120.0414),
            highway: "US-50"
        ),
        CorridorDefinition(
            id: "ca88-carson",
            label: "CA-88 (Carson Pass)",
            shortLabel: "CA-88",
            coordinate: CLLocationCoordinate2D(latitude: 38.7056, longitude: -119.9880),
            highway: "CA-88"
        ),
        CorridorDefinition(
            id: "ca89-tahoe",
            label: "CA-89 (Tahoe Basin)",
            shortLabel: "CA-89",
            coordinate: CLLocationCoordinate2D(latitude: 38.9619, longitude: -120.0860),
            highway: "CA-89"
        ),
        CorridorDefinition(
            id: "ca28-laketahoe",
            label: "CA-28 (Lake Tahoe)",
            shortLabel: "CA-28",
            coordinate: CLLocationCoordinate2D(latitude: 39.1686, longitude: -120.1429),
            highway: "CA-28"
        ),
        CorridorDefinition(
            id: "ca267-kings",
            label: "CA-267 (Truckee to Kings Beach)",
            shortLabel: "CA-267",
            coordinate: CLLocationCoordinate2D(latitude: 39.3312, longitude: -120.1701),
            highway: "CA-267"
        )
    ]
}
