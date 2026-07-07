//
//  TriviaAPIService.swift
//  screenfare
//
//  Created by Claude Code
//

import Foundation

enum ErrorCategory {
    case noConnection  // No WiFi/cellular - show "No connection" with Try again
    case generic       // Other errors - show generic message with "Switch to Math"
}

enum TriviaAPIError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case noQuestionsAvailable
    case rateLimitExceeded
    case invalidParameters
    case sessionTokenError
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .noQuestionsAvailable:
            return "No questions available for this category/difficulty"
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .invalidParameters:
            return "Invalid trivia parameters"
        case .sessionTokenError:
            return "Session token error"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }

    var errorCategory: ErrorCategory {
        switch self {
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain &&
               nsError.code == NSURLErrorNotConnectedToInternet {
                return .noConnection
            }
            return .generic
        default:
            return .generic
        }
    }
}

class TriviaAPIService {
    static let shared = TriviaAPIService()

    private let baseURL = "https://opentdb.com/api.php"
    private let session: URLSession

    // Rate limiting: max 1 request per 5 seconds
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 5.0

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        self.session = URLSession(configuration: config)
    }

    /// Fetches a trivia question from the Open Trivia Database API
    /// - Parameters:
    ///   - categoryID: The category ID (9=General Knowledge, 17=Science, etc.)
    ///   - difficulty: "easy", "medium", or "hard"
    ///   - retryCount: Internal retry counter (default 0)
    /// - Returns: A decoded TriviaQuestion
    func fetchQuestion(categoryID: String, difficulty: String, retryCount: Int = 0) async throws -> TriviaQuestion {
        // Rate limiting check
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minimumRequestInterval {
                let waitTime = minimumRequestInterval - timeSinceLastRequest
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }

        // Build URL with parameters
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "amount", value: "1"),
            URLQueryItem(name: "type", value: "multiple"),
            URLQueryItem(name: "category", value: categoryID),
            URLQueryItem(name: "difficulty", value: difficulty.lowercased())
        ]

        guard let url = components.url else {
            throw TriviaAPIError.invalidParameters
        }

        do {
            // Make request
            let (data, response) = try await session.data(from: url)
            lastRequestTime = Date()

            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw TriviaAPIError.invalidResponse
            }

            // Decode response
            let decoder = JSONDecoder()
            let triviaResponse: TriviaAPIResponse
            do {
                triviaResponse = try decoder.decode(TriviaAPIResponse.self, from: data)
            } catch {
                throw TriviaAPIError.decodingError(error)
            }

            // Check response code
            switch triviaResponse.responseCode {
            case 0: // Success
                guard let question = triviaResponse.results.first else {
                    throw TriviaAPIError.noQuestionsAvailable
                }
                return question
            case 1:
                throw TriviaAPIError.noQuestionsAvailable
            case 2:
                throw TriviaAPIError.invalidParameters
            case 3, 4:
                throw TriviaAPIError.sessionTokenError
            case 5:
                throw TriviaAPIError.rateLimitExceeded
            default:
                throw TriviaAPIError.invalidResponse
            }
        } catch {
            // Check if error is retryable and we haven't exceeded max retries
            if retryCount < 3 && isRetryableError(error) {
                // Exponential backoff: 1s, 2s, 4s
                let delay = pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await fetchQuestion(categoryID: categoryID, difficulty: difficulty, retryCount: retryCount + 1)
            }

            // Not retryable or max retries exceeded - throw wrapped error
            throw TriviaAPIError.networkError(error)
        }
    }

    /// Determines if an error is worth retrying
    private func isRetryableError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut,
                 NSURLErrorCannotFindHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorCannotConnectToHost:
                return true
            case NSURLErrorNotConnectedToInternet:
                return false // Don't retry - no connection
            default:
                return false
            }
        }
        return false
    }
}
