import Foundation

enum OpenMeteoSnowfallError: Error {
    case invalidResponse
    case badStatus(Int)
    case invalidData
}

struct OpenMeteoSnowfallResponse: Decodable {
    struct DailyUnits: Decodable {
        let snowfallSum: String

        private enum CodingKeys: String, CodingKey {
            case snowfallSum = "snowfall_sum"
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let snowfallSum: [Double?]

        private enum CodingKeys: String, CodingKey {
            case time
            case snowfallSum = "snowfall_sum"
        }
    }

    let daily: Daily
    let dailyUnits: DailyUnits
    let timezone: String?

    private enum CodingKeys: String, CodingKey {
        case daily
        case dailyUnits = "daily_units"
        case timezone
    }
}

struct OpenMeteoSnowfallClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchSnowfallDaily(lat: Double, lon: Double) async throws -> OpenMeteoSnowfallResponse {
        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else {
            throw OpenMeteoSnowfallError.invalidData
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "daily", value: "snowfall_sum"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "past_days", value: "8"),
            URLQueryItem(name: "forecast_days", value: "1")
        ]

        guard let url = components.url else {
            throw OpenMeteoSnowfallError.invalidData
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenMeteoSnowfallError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw OpenMeteoSnowfallError.badStatus(httpResponse.statusCode)
        }
        guard !data.isEmpty else {
            throw OpenMeteoSnowfallError.invalidData
        }

        return try JSONDecoder().decode(OpenMeteoSnowfallResponse.self, from: data)
    }
}
