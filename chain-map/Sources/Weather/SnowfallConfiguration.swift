import Foundation

struct SnowfallConfiguration {
    let isEnabled: Bool

    static func fromBundle(_ bundle: Bundle = .main) -> SnowfallConfiguration {
        let enabled = bundle.boolValue(forInfoKey: "SnowfallEnabled") ?? true
        return SnowfallConfiguration(isEnabled: enabled)
    }
}

private extension Bundle {
    func boolValue(forInfoKey key: String) -> Bool? {
        if let value = object(forInfoDictionaryKey: key) as? Bool {
            return value
        }
        if let value = object(forInfoDictionaryKey: key) as? String {
            return (value as NSString).boolValue
        }
        return nil
    }
}
