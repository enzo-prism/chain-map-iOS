import Foundation

enum LiveDataParsing {
    static let isoFormatter = ISO8601DateFormatter()

    static func normalizeRoute(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let upper = trimmed.uppercased()

        let patterns: [(String, String)] = [
            ("\\bI\\s*-?\\s*80\\b", "I-80"),
            ("\\bINTERSTATE\\s*80\\b", "I-80"),
            ("\\bU\\.?\\s*S\\.?\\s*-?\\s*50\\b", "US-50"),
            ("\\bUS\\s*-?\\s*50\\b", "US-50"),
            ("\\bCA\\s*-?\\s*88\\b", "CA-88"),
            ("\\bSR\\s*-?\\s*88\\b", "CA-88"),
            ("\\bSTATE\\s+ROUTE\\s*88\\b", "CA-88"),
            ("\\bCA\\s*-?\\s*89\\b", "CA-89"),
            ("\\bSR\\s*-?\\s*89\\b", "CA-89"),
            ("\\bSTATE\\s+ROUTE\\s*89\\b", "CA-89"),
            ("\\bCA\\s*-?\\s*28\\b", "CA-28"),
            ("\\bSR\\s*-?\\s*28\\b", "CA-28"),
            ("\\bSTATE\\s+ROUTE\\s*28\\b", "CA-28"),
            ("\\bCA\\s*-?\\s*267\\b", "CA-267"),
            ("\\bSR\\s*-?\\s*267\\b", "CA-267"),
            ("\\bSTATE\\s+ROUTE\\s*267\\b", "CA-267")
        ]

        for (pattern, route) in patterns {
            if upper.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return route
            }
        }

        let digitsOnly = upper.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if digitsOnly == upper || upper == digitsOnly {
            switch digitsOnly {
            case "80":
                return "I-80"
            case "50":
                return "US-50"
            case "88":
                return "CA-88"
            case "89":
                return "CA-89"
            case "28":
                return "CA-28"
            case "267":
                return "CA-267"
            default:
                break
            }
        }

        return nil
    }

    static func normalizeDirection(_ text: String) -> String? {
        let upper = text.uppercased()
        if upper.contains("EAST") || upper == "E" || upper == "EB" {
            return "EB"
        }
        if upper.contains("WEST") || upper == "W" || upper == "WB" {
            return "WB"
        }
        if upper.contains("NORTH") || upper == "N" || upper == "NB" {
            return "NB"
        }
        if upper.contains("SOUTH") || upper == "S" || upper == "SB" {
            return "SB"
        }
        return nil
    }

    static func normalizeChainStatus(_ text: String) -> String {
        let upper = text.uppercased().replacingOccurrences(of: " ", with: "")
        if upper.contains("R-0") || upper.contains("R0") {
            return "R-0"
        }
        if upper.contains("R-1") || upper.contains("R1") {
            return "R-1"
        }
        if upper.contains("R-2") || upper.contains("R2") {
            return "R-2"
        }
        if upper.contains("R-3") || upper.contains("R3") {
            return "R-3"
        }
        if upper.contains("RC") {
            return "RC"
        }
        return upper
    }

    static func parseCaltransStatusDate(date: String, time: String) -> Date? {
        let combined = "\(date) \(time)".trimmingCharacters(in: .whitespacesAndNewlines)
        guard !combined.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        let formats = [
            "M/d/yyyy H:mm",
            "M/d/yyyy h:mm a",
            "M/d/yy H:mm",
            "M/d/yy h:mm a",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: combined) {
                return date
            }
        }

        return nil
    }

    static func parseEpoch(_ value: Double?) -> Date? {
        guard let value else { return nil }
        let seconds = value > 1_000_000_000_000 ? value / 1000 : value
        return Date(timeIntervalSince1970: seconds)
    }
}
