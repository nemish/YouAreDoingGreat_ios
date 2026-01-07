import Foundation
@testable import YouAreDoingGreat

// MARK: - Mock API Client
// Mock implementation of APIClient for testing
// Allows tests to control network responses and errors

@MainActor
final class MockAPIClient: APIClient {
    // MARK: - Mock Configuration

    var responses: [String: Result<Data, Error>] = [:]
    var requestHistory: [(endpoint: APIEndpoint, method: HTTPMethod)] = []

    // MARK: - APIClient Implementation

    func request<T: Decodable, B: Encodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: B?
    ) async throws -> T {
        // Record the request
        requestHistory.append((endpoint, method))

        // Get the endpoint path for lookup
        let path = endpoint.path

        // Check if we have a mock response for this endpoint
        guard let result = responses[path] else {
            throw MomentError.serverError(message: "No mock response configured for \(path)")
        }

        // Handle the result
        switch result {
        case .success(let data):
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)

        case .failure(let error):
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Configure a successful response for an endpoint
    func setResponse<T: Encodable>(for path: String, response: T) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(response)
        responses[path] = .success(data)
    }

    /// Configure an error response for an endpoint
    func setError(for path: String, error: Error) {
        responses[path] = .failure(error)
    }

    /// Clear all mock responses and history
    func reset() {
        responses.removeAll()
        requestHistory.removeAll()
    }

    /// Check if a request was made to an endpoint
    func didRequest(endpoint: APIEndpoint) -> Bool {
        return requestHistory.contains { $0.endpoint.path == endpoint.path }
    }

    /// Get the number of requests made to an endpoint
    func requestCount(for endpoint: APIEndpoint) -> Int {
        return requestHistory.filter { $0.endpoint.path == endpoint.path }.count
    }
}
