import Foundation
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "api-client")

// MARK: - Default API Client
// URLSession-based implementation of APIClient with automatic header injection

final class DefaultAPIClient: APIClient {
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    init(session: URLSession = .shared) {
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

        // Handle error status codes
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error response
            if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data) {
                if errorResponse.error.code == .dailyLimitReached {
                    throw MomentError.dailyLimitReached(message: errorResponse.error.message)
                } else {
                    throw MomentError.serverError(message: errorResponse.error.message)
                }
            }
            throw MomentError.invalidResponse
        }

        // Decode successful response
        do {
            let decoded = try jsonDecoder.decode(T.self, from: data)
            return decoded
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            throw MomentError.decodingError(error)
        }
    }
}
