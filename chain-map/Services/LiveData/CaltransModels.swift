import Foundation

struct CaltransChainControlResponse: Decodable {
    let data: [CaltransChainControlWrapper]
}

struct CaltransChainControlWrapper: Decodable {
    let cc: CaltransChainControlRecord?
}

struct CaltransChainControlRecord: Decodable {
    let index: String
    let district: String
    let locationName: String
    let nearbyPlace: String
    let latitude: Double?
    let longitude: Double?
    let direction: String
    let county: String
    let route: String
    let status: String
    let statusDescription: String
    let statusDate: String
    let statusTime: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        index = container.decodeString(for: ["index", "Index", "ID"])
        district = container.decodeString(for: ["district", "District"])
        locationName = container.decodeString(for: ["locationName", "LocationName"])
        nearbyPlace = container.decodeString(for: ["nearbyPlace", "NearbyPlace"])
        latitude = container.decodeDouble(for: ["latitude", "Latitude"])
        longitude = container.decodeDouble(for: ["longitude", "Longitude"])
        direction = container.decodeString(for: ["direction", "Direction", "dir", "Dir"])
        county = container.decodeString(for: ["county", "County"])
        route = container.decodeString(for: ["route", "Route"])
        status = container.decodeString(for: ["status", "Status"])
        statusDescription = container.decodeString(for: ["statusDescription", "StatusDescription"])
        statusDate = container.decodeString(for: ["statusDate", "StatusDate"])
        statusTime = container.decodeString(for: ["statusTime", "StatusTime"])
    }
}

struct CaltransLaneClosureResponse: Decodable {
    let data: [CaltransLaneClosureWrapper]
}

struct CaltransLaneClosureWrapper: Decodable {
    let lcs: CaltransLaneClosureRecord?
}

struct CaltransLaneClosureRecord: Decodable {
    let index: String
    let travelFlowDirection: String
    let beginRoute: String
    let beginLatitude: Double?
    let beginLongitude: Double?
    let beginLocationName: String
    let beginNearbyPlace: String
    let endRoute: String
    let endLatitude: Double?
    let endLongitude: Double?
    let endLocationName: String
    let endNearbyPlace: String
    let typeOfClosure: String
    let typeOfWork: String
    let lanesClosed: Int?
    let totalExistingLanes: Int?
    let estimatedDelay: String
    let closureStartEpoch: Double?
    let closureEndEpoch: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        index = container.decodeString(for: ["index", "Index", "ID"])
        travelFlowDirection = container.decodeString(for: ["travelFlowDirection", "TravelFlowDirection"])
        beginRoute = container.decodeString(for: ["beginRoute", "BeginRoute"])
        beginLatitude = container.decodeDouble(for: ["beginLatitude", "BeginLatitude"])
        beginLongitude = container.decodeDouble(for: ["beginLongitude", "BeginLongitude"])
        beginLocationName = container.decodeString(for: ["beginLocationName", "BeginLocationName"])
        beginNearbyPlace = container.decodeString(for: ["beginNearbyPlace", "BeginNearbyPlace"])
        endRoute = container.decodeString(for: ["endRoute", "EndRoute"])
        endLatitude = container.decodeDouble(for: ["endLatitude", "EndLatitude"])
        endLongitude = container.decodeDouble(for: ["endLongitude", "EndLongitude"])
        endLocationName = container.decodeString(for: ["endLocationName", "EndLocationName"])
        endNearbyPlace = container.decodeString(for: ["endNearbyPlace", "EndNearbyPlace"])
        typeOfClosure = container.decodeString(for: ["typeOfClosure", "TypeOfClosure"])
        typeOfWork = container.decodeString(for: ["typeOfWork", "TypeOfWork"])
        lanesClosed = container.decodeInt(for: ["lanesClosed", "LanesClosed"])
        totalExistingLanes = container.decodeInt(for: ["totalExistingLanes", "TotalExistingLanes"])
        estimatedDelay = container.decodeString(for: ["estimatedDelay", "EstimatedDelay"])
        closureStartEpoch = container.decodeDouble(for: ["closureStartEpoch", "ClosureStartEpoch"])
        closureEndEpoch = container.decodeDouble(for: ["closureEndEpoch", "ClosureEndEpoch"])
    }
}

struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where Key == AnyCodingKey {
    func decodeString(for keys: [String]) -> String {
        for key in keys {
            let codingKey = AnyCodingKey(stringValue: key)
            if let value = try? decodeIfPresent(String.self, forKey: codingKey) {
                let cleaned = value.cleanedOptionalString()
                if let cleaned {
                    return cleaned
                }
            }
            if let value = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return String(value)
            }
            if let value = try? decodeIfPresent(Double.self, forKey: codingKey) {
                return String(value)
            }
        }
        return ""
    }

    func decodeDouble(for keys: [String]) -> Double? {
        for key in keys {
            let codingKey = AnyCodingKey(stringValue: key)
            if let value = try? decodeIfPresent(Double.self, forKey: codingKey) {
                return value
            }
            if let value = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return Double(value)
            }
            if let value = try? decodeIfPresent(String.self, forKey: codingKey) {
                if let cleaned = value.cleanedOptionalString(), let parsed = Double(cleaned) {
                    return parsed
                }
            }
        }
        return nil
    }

    func decodeInt(for keys: [String]) -> Int? {
        for key in keys {
            let codingKey = AnyCodingKey(stringValue: key)
            if let value = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return value
            }
            if let value = try? decodeIfPresent(Double.self, forKey: codingKey) {
                return Int(value)
            }
            if let value = try? decodeIfPresent(String.self, forKey: codingKey) {
                if let cleaned = value.cleanedOptionalString(), let parsed = Int(cleaned) {
                    return parsed
                }
            }
        }
        return nil
    }
}

private extension String {
    func cleanedOptionalString() -> String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.caseInsensitiveCompare("Not Reported") == .orderedSame {
            return nil
        }
        return trimmed
    }
}
