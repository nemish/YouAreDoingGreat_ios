import Foundation

// MARK: - API Error Models
// Based on API_SCHEMA.json error response format

struct APIErrorResponse: Decodable {
    let error: APIErrorDetail
    let meta: [String: AnyCodable]?

    struct APIErrorDetail: Decodable {
        let code: APIErrorCode
        let message: String
    }
}

enum APIErrorCode: String, Decodable {
    case unauthorized = "UNAUTHORIZED"
    case restrictedAccess = "RESTRICTED_ACCESS"
    case internalServerError = "INTERNAL_SERVER_ERROR"
    case dailyLimitReached = "DAILY_LIMIT_REACHED"
    case invalidCursor = "INVALID_CURSOR"
    case momentNotFound = "MOMENT_NOT_FOUND"
    case forbidden = "FORBIDDEN"
    case invalidRequest = "INVALID_REQUEST"
}

// MARK: - AnyCodable Helper
// For decoding meta dictionaries with mixed types

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Moment Error
// Domain-specific errors for moment operations

enum MomentError: LocalizedError {
    case dailyLimitReached(message: String)
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case unauthorized
    case serverError(message: String)

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to decode server response"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let message):
            return message
        }
    }

    var isDailyLimitError: Bool {
        if case .dailyLimitReached = self {
            return true
        }
        return false
    }
}
