import Foundation

struct LiveDataConfiguration {
    let useDotFeedsDirectly: Bool
    let nevadaProxyBaseURL: URL?

    static func fromBundle(_ bundle: Bundle = .main) -> LiveDataConfiguration {
        let useDotFeeds = bundle.boolValue(forInfoKey: "UseDotFeedsDirectly") ?? true
        let nevadaBaseURL = bundle.urlValue(forInfoKey: "Nevada511ProxyBaseURL")
        return LiveDataConfiguration(
            useDotFeedsDirectly: useDotFeeds,
            nevadaProxyBaseURL: nevadaBaseURL
        )
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

    func urlValue(forInfoKey key: String) -> URL? {
        guard let value = object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme == "https" else {
            return nil
        }
        return url
    }
}
