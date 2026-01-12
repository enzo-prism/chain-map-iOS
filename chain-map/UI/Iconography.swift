import Foundation

enum AppSymbol {
    static let tabMap = "map"
    static let tabStatus = "list.bullet"
    static let refresh = "arrow.clockwise"
    static let about = "info.circle"
    static let lastUpdated = "clock"
    static let stale = "exclamationmark.triangle.fill"
    static let error = "exclamationmark.circle.fill"
    static let keyPaths = "key.fill"
    static let allCorridors = "list.bullet"
    static let dataSource = "info.circle"

    static func severitySymbol(for severity: CorridorSeverity) -> String {
        switch severity {
        case .ok:
            return "checkmark.circle.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .chains:
            return "snowflake"
        case .closed:
            return "xmark.octagon.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
}
