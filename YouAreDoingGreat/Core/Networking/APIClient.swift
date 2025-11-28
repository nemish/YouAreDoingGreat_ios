import Foundation

// MARK: - API Client Protocol
// Generic network layer abstraction for all API calls

protocol APIClient {
    func request<T: Decodable, B: Encodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: B?
    ) async throws -> T
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Endpoints

enum APIEndpoint {
    case moments(cursor: String?, limit: Int)
    case moment(id: String)
    case updateMoment(id: String)
    case deleteMoment(id: String)
    case userProfile
    case userStats
    case submitFeedback

    var path: String {
        switch self {
        case .moments(let cursor, let limit):
            var components = URLComponents(string: "\(AppConfig.apiBaseURL)/moments")
            components?.queryItems = [
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            if let cursor = cursor {
                components?.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
            }
            return components?.url?.absoluteString ?? "\(AppConfig.apiBaseURL)/moments"

        case .moment(let id):
            return "\(AppConfig.apiBaseURL)/moments/\(id)"

        case .updateMoment(let id):
            return "\(AppConfig.apiBaseURL)/moments/\(id)"

        case .deleteMoment(let id):
            return "\(AppConfig.apiBaseURL)/moments/\(id)"

        case .userProfile:
            return "\(AppConfig.apiBaseURL)/user/me"

        case .userStats:
            return "\(AppConfig.apiBaseURL)/user/stats"

        case .submitFeedback:
            return "\(AppConfig.apiBaseURL)/user/feedback"
        }
    }

    var url: URL? {
        URL(string: path)
    }
}
