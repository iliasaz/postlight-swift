import Foundation

/// Errors that can occur during parsing.
public enum ParserError: Error, LocalizedError, Sendable {
    /// The provided URL is invalid or malformed.
    case invalidURL(String)

    /// Failed to fetch the resource from the URL.
    case fetchFailed(message: String)

    /// HTTP request returned a non-200 status code.
    case httpError(statusCode: Int, message: String)

    /// The response content type is not supported.
    case unsupportedContentType(String)

    /// The response content exceeds the maximum allowed size.
    case contentTooLarge(size: Int, maxSize: Int)

    /// Failed to detect or decode the character encoding.
    case encodingError(String)

    /// Failed to parse the HTML document.
    case parseError(String)

    /// No content could be extracted from the document.
    case contentNotFound

    /// The request timed out.
    case timeout(TimeInterval)

    /// A generic error with a message.
    case generic(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url). Please check the URL format and try again."
        case .fetchFailed(let message):
            return "Failed to fetch resource: \(message)"
        case .httpError(let statusCode, let message):
            return "HTTP error \(statusCode): \(message)"
        case .unsupportedContentType(let contentType):
            return "Unsupported content type: \(contentType). Only HTML content is supported."
        case .contentTooLarge(let size, let maxSize):
            return "Content too large (\(size) bytes). Maximum allowed: \(maxSize) bytes."
        case .encodingError(let message):
            return "Character encoding error: \(message)"
        case .parseError(let message):
            return "HTML parsing error: \(message)"
        case .contentNotFound:
            return "No extractable content found in the document."
        case .timeout(let duration):
            return "Request timed out after \(duration) seconds."
        case .generic(let message):
            return message
        }
    }
}

/// Result type that can represent either a successful parse or an error.
public struct ParserResult: Sendable {
    /// The parsed article, if successful.
    public let article: ParsedArticle?

    /// Whether an error occurred.
    public let error: Bool

    /// Error message, if an error occurred.
    public let message: String?

    /// Creates a successful result.
    public static func success(_ article: ParsedArticle) -> ParserResult {
        ParserResult(article: article, error: false, message: nil)
    }

    /// Creates an error result.
    public static func failure(_ message: String) -> ParserResult {
        ParserResult(article: nil, error: true, message: message)
    }
}
