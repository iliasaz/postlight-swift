import Foundation
import SwiftSoup

/// A wrapper around SwiftSoup providing a jQuery-like interface for HTML manipulation.
///
/// This abstraction allows the parser to work with HTML documents in a way similar
/// to the original JavaScript implementation using cheerio.
public final class Document: @unchecked Sendable {
    /// The underlying SwiftSoup document.
    private var doc: SwiftSoup.Document

    /// The base URL for resolving relative links.
    public let baseURL: URL?

    /// Creates a Document from HTML string.
    /// - Parameters:
    ///   - html: The HTML content to parse.
    ///   - baseURL: Base URL for resolving relative links.
    /// - Throws: `ParserError.parseError` if HTML parsing fails.
    public init(html: String, baseURL: URL? = nil) throws {
        do {
            self.doc = try SwiftSoup.parse(html)
            self.baseURL = baseURL
        } catch {
            throw ParserError.parseError("Failed to parse HTML: \(error.localizedDescription)")
        }
    }

    /// Creates a Document from Data with encoding detection.
    /// - Parameters:
    ///   - data: The raw HTML data.
    ///   - encoding: Optional encoding hint from HTTP headers.
    ///   - baseURL: Base URL for resolving relative links.
    /// - Throws: `ParserError.encodingError` or `ParserError.parseError`.
    public init(data: Data, encoding: String.Encoding? = nil, baseURL: URL? = nil) throws {
        // Try to decode with provided encoding or detect it
        let html: String
        if let encoding = encoding, let decoded = String(data: data, encoding: encoding) {
            html = decoded
        } else if let detected = Document.detectAndDecode(data: data) {
            html = detected
        } else {
            throw ParserError.encodingError("Failed to detect or decode character encoding")
        }

        do {
            self.doc = try SwiftSoup.parse(html)
            self.baseURL = baseURL

            // Check for encoding in meta tags and re-parse if different
            if let metaEncoding = try? self.getMetaEncoding(),
               let properEncoding = Document.stringEncoding(from: metaEncoding),
               properEncoding != (encoding ?? .utf8),
               let reDecoded = String(data: data, encoding: properEncoding) {
                self.doc = try SwiftSoup.parse(reDecoded)
            }
        } catch let error as ParserError {
            throw error
        } catch {
            throw ParserError.parseError("Failed to parse HTML: \(error.localizedDescription)")
        }
    }

    // MARK: - Selection

    /// Selects elements matching a CSS selector.
    /// - Parameter selector: CSS selector string.
    /// - Returns: Array of matching elements.
    public func select(_ selector: String) throws -> [Element] {
        try doc.select(selector).array().map { Element(element: $0, document: self) }
    }

    /// Selects the first element matching a CSS selector.
    /// - Parameter selector: CSS selector string.
    /// - Returns: First matching element, or nil if none found.
    public func selectFirst(_ selector: String) throws -> Element? {
        guard let element = try doc.select(selector).first() else { return nil }
        return Element(element: element, document: self)
    }

    // MARK: - Common Selections

    /// Returns the document's body element.
    public var body: Element? {
        doc.body().map { Element(element: $0, document: self) }
    }

    /// Returns the document's head element.
    public var head: Element? {
        doc.head().map { Element(element: $0, document: self) }
    }

    /// Returns the document's title.
    public var title: String? {
        try? doc.title()
    }

    /// Returns the full HTML of the document.
    public func html() throws -> String {
        try doc.html()
    }

    /// Returns the text content of the document.
    public func text() throws -> String {
        try doc.text()
    }

    // MARK: - Meta Tags

    /// Gets all meta tag names in the document.
    public func metaNames() throws -> [String] {
        try doc.select("meta[name]").array().compactMap { try? $0.attr("name") }
    }

    /// Gets a meta tag value by name.
    public func meta(name: String) throws -> String? {
        try doc.select("meta[name='\(name)']").first()?.attr("content")
    }

    /// Gets a meta tag value by property.
    public func meta(property: String) throws -> String? {
        try doc.select("meta[property='\(property)']").first()?.attr("content")
    }

    // MARK: - Utilities

    /// Whether this appears to be a WordPress site.
    public var isWordPress: Bool {
        (try? doc.select("meta[name='generator'][content*='WordPress']").first()) != nil
    }

    /// Whether the document has any children.
    public var hasChildren: Bool {
        doc.children().size() > 0
    }

    // MARK: - Encoding Detection

    private func getMetaEncoding() throws -> String? {
        // Check <meta http-equiv="content-type">
        if let contentType = try doc.select("meta[http-equiv=content-type i]").first()?.attr("content") {
            return Document.extractCharset(from: contentType)
        }
        // Check <meta charset="...">
        if let charset = try doc.select("meta[charset]").first()?.attr("charset") {
            return charset
        }
        return nil
    }

    private static func extractCharset(from contentType: String) -> String? {
        let pattern = /charset=([^\s;]+)/
        if let match = contentType.firstMatch(of: pattern) {
            return String(match.1).lowercased()
        }
        return nil
    }

    private static func detectAndDecode(data: Data) -> String? {
        // Try common encodings in order of likelihood
        let encodings: [String.Encoding] = [
            .utf8,
            .isoLatin1,
            .windowsCP1252,
            .utf16,
            .utf16BigEndian,
            .utf16LittleEndian,
        ]

        for encoding in encodings {
            if let decoded = String(data: data, encoding: encoding) {
                return decoded
            }
        }

        return nil
    }

    private static func stringEncoding(from name: String) -> String.Encoding? {
        switch name.lowercased() {
        case "utf-8", "utf8":
            return .utf8
        case "iso-8859-1", "latin1", "latin-1":
            return .isoLatin1
        case "windows-1252", "cp1252":
            return .windowsCP1252
        case "utf-16", "utf16":
            return .utf16
        case "ascii", "us-ascii":
            return .ascii
        default:
            return nil
        }
    }
}
