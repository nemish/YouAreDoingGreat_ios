import Foundation
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "api-client")

// MARK: - Default API Client
// URLSession-based implementation of APIClient with automatic header injection

final class DefaultAPIClient: APIClient, @unchecked Sendable {
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    nonisolated init(session: URLSession = .shared) {
        self.session = session
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
    }

    func request<T: Decodable, B: Encodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: B?
    ) async throws -> T {
        guard let url = endpoint.url else {
            throw MomentError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add user ID header for authentication
        request.setValue(UserIDProvider.shared.userID, forHTTPHeaderField: AppConfig.userIdHeaderKey)

        // Add app token header for API access validation
        request.setValue(AppConfig.appToken, forHTTPHeaderField: AppConfig.appTokenHeaderKey)

        // Add request body if provided
        if let body = body {
            request.httpBody = try jsonEncoder.encode(body)
        }

        // Set timeout
        request.timeoutInterval = AppConfig.networkTimeout

        logger.debug("API Request: \(method.rawValue) \(url.absoluteString)")

        // Perform request
        let (data, response) = try await session.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw MomentError.invalidResponse
        }

        logger.debug("API Response: \(httpResponse.statusCode)")

        // Handle 304 Not Modified - data should be from cache
        if httpResponse.statusCode == 304 {
            // For 304, URLSession returns cached data automatically
            // If data is empty, it means cache wasn't properly set up
            if data.isEmpty {
                logger.error("304 response but no cached data available")
                throw MomentError.invalidResponse
            }
        }

        // Handle error status codes
        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 304 else {
            // Try to parse error response
            if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data) {
                switch errorResponse.error.code {
                case .dailyLimitReached:
                    throw MomentError.dailyLimitReached(message: errorResponse.error.message)
                default:
                    throw MomentError.serverError(message: errorResponse.error.message)
                }
            }
            throw MomentError.invalidResponse
        }

        do {
            let decoded = try jsonDecoder.decode(T.self, from: data)
            return decoded
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            logger.error("Decoding error details: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    logger.error("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    logger.error("Type '\(type)' mismatch: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    logger.error("Value '\(type)' not found: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    logger.error("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    logger.error("Unknown decoding error")
                }
            }
            throw MomentError.decodingError(error)
        }
    }
}
