import Foundation

nonisolated enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case transport(URLError.Code)
    case http(statusCode: Int, messages: [String])
    case decoding(String)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The request URL is invalid."
        case .invalidResponse:
            "The server returned an invalid response."
        case let .transport(code):
            URLError(code).localizedDescription
        case let .http(statusCode, messages):
            messages.first ?? "The server returned HTTP \(statusCode)."
        case let .decoding(message):
            "The server response could not be decoded: \(message)"
        }
    }
}
