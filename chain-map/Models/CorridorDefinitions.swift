import CoreLocation

struct CorridorDefinition: Identifiable {
    let id: String
    let label: String
    let shortLabel: String
    let coordinate: CLLocationCoordinate2D
    let highway: String
    let polyline: [CLLocationCoordinate2D]
}

extension CorridorDefinition {
    static let keyPathIds: [String] = [
        "i80-donner",
        "us50-echo",
        "ca88-carson",
        "ca89-tahoe",
        "ca28-laketahoe",
        "ca267-kings"
    ]

    static let all: [CorridorDefinition] = [
        CorridorDefinition(
            id: "i80-donner",
            label: "I-80 (Donner Summit)",
            shortLabel: "I-80",
            coordinate: CLLocationCoordinate2D(latitude: 39.3206, longitude: -120.3327),
            highway: "I-80",
            polyline: [
                CLLocationCoordinate2D(latitude: 38.8966, longitude: -121.0769),
                CLLocationCoordinate2D(latitude: 39.1355, longitude: -120.8075),
                CLLocationCoordinate2D(latitude: 39.3206, longitude: -120.3327),
                CLLocationCoordinate2D(latitude: 39.3270, longitude: -120.1833)
            ]
        ),
        CorridorDefinition(
            id: "us50-echo",
            label: "US-50 (Echo Summit)",
            shortLabel: "US-50",
            coordinate: CLLocationCoordinate2D(latitude: 38.8154, longitude: -120.0414),
            highway: "US-50",
            polyline: [
                CLLocationCoordinate2D(latitude: 38.7296, longitude: -120.7985),
                CLLocationCoordinate2D(latitude: 38.7783, longitude: -120.5172),
                CLLocationCoordinate2D(latitude: 38.8154, longitude: -120.0414),
                CLLocationCoordinate2D(latitude: 38.9399, longitude: -119.9772)
            ]
        ),
        CorridorDefinition(
            id: "ca88-carson",
            label: "CA-88 (Carson Pass)",
            shortLabel: "CA-88",
            coordinate: CLLocationCoordinate2D(latitude: 38.7056, longitude: -119.9880),
            highway: "CA-88",
            polyline: [
                CLLocationCoordinate2D(latitude: 38.3488, longitude: -120.7747),
                CLLocationCoordinate2D(latitude: 38.5524, longitude: -120.2767),
                CLLocationCoordinate2D(latitude: 38.6841, longitude: -120.0661),
                CLLocationCoordinate2D(latitude: 38.7056, longitude: -119.9880)
            ]
        ),
        CorridorDefinition(
            id: "ca89-tahoe",
            label: "CA-89 (Tahoe Basin)",
            shortLabel: "CA-89",
            coordinate: CLLocationCoordinate2D(latitude: 38.9619, longitude: -120.0860),
            highway: "CA-89",
            polyline: [
                CLLocationCoordinate2D(latitude: 39.1638, longitude: -120.1371),
                CLLocationCoordinate2D(latitude: 39.0302, longitude: -120.1186),
                CLLocationCoordinate2D(latitude: 38.9456, longitude: -120.1022),
                CLLocationCoordinate2D(latitude: 38.8555, longitude: -120.0424)
            ]
        ),
        CorridorDefinition(
            id: "ca28-laketahoe",
            label: "CA-28 (Lake Tahoe)",
            shortLabel: "CA-28",
            coordinate: CLLocationCoordinate2D(latitude: 39.1686, longitude: -120.1429),
            highway: "CA-28",
            polyline: [
                CLLocationCoordinate2D(latitude: 39.1675, longitude: -120.1404),
                CLLocationCoordinate2D(latitude: 39.2063, longitude: -120.1049),
                CLLocationCoordinate2D(latitude: 39.2390, longitude: -120.0510),
                CLLocationCoordinate2D(latitude: 39.2480, longitude: -120.0238)
            ]
        ),
        CorridorDefinition(
            id: "ca267-kings",
            label: "CA-267 (Truckee to Kings Beach)",
            shortLabel: "CA-267",
            coordinate: CLLocationCoordinate2D(latitude: 39.3312, longitude: -120.1701),
            highway: "CA-267",
            polyline: [
                CLLocationCoordinate2D(latitude: 39.3270, longitude: -120.1833),
                CLLocationCoordinate2D(latitude: 39.3083, longitude: -120.0819),
                CLLocationCoordinate2D(latitude: 39.2375, longitude: -120.0260)
            ]
        )
    ]
}
