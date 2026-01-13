import Foundation

/// The output format for extracted content.
public enum ContentType: String, Sendable, CaseIterable {
    /// Return content as sanitized HTML (default).
    case html
    /// Return content converted to Markdown.
    case markdown
    /// Return content as plain text with HTML tags stripped.
    case text
}

/// Configuration options for the parser.
public struct ParserOptions: Sendable {
    /// Whether to fetch and merge all pages for multi-page articles.
    /// Default: `true`
    public var fetchAllPages: Bool

    /// Whether to fall back to generic extraction if custom extractor fails.
    /// Default: `true`
    public var fallback: Bool

    /// The output format for the content field.
    /// Default: `.html`
    public var contentType: ContentType

    /// Custom HTTP headers to include in requests.
    public var headers: [String: String]

    /// Custom extractor to use for this parse operation.
    public var customExtractor: (any Extractor)?

    /// Extended extraction rules for custom fields.
    public var extend: [String: ExtractionConfig]?

    /// Creates parser options with default values.
    public init(
        fetchAllPages: Bool = true,
        fallback: Bool = true,
        contentType: ContentType = .html,
        headers: [String: String] = [:],
        customExtractor: (any Extractor)? = nil,
        extend: [String: ExtractionConfig]? = nil
    ) {
        self.fetchAllPages = fetchAllPages
        self.fallback = fallback
        self.contentType = contentType
        self.headers = headers
        self.customExtractor = customExtractor
        self.extend = extend
    }

    /// Default parser options.
    public static let `default` = ParserOptions()
}

/// Configuration for extracting a specific field.
public struct ExtractionConfig: Sendable {
    /// CSS selectors to try in order.
    public let selectors: [Selector]

    /// Whether to apply the default cleaner for this field type.
    /// Default: `true`
    public var defaultCleaner: Bool

    /// Whether multiple matches should be returned.
    /// Default: `false`
    public var allowMultiple: Bool

    /// Element transformations to apply.
    public var transforms: [String: @Sendable (Element) -> Void]?

    /// CSS selectors for elements to remove from the result.
    public var clean: [String]?

    public init(
        selectors: [Selector],
        defaultCleaner: Bool = true,
        allowMultiple: Bool = false,
        transforms: [String: @Sendable (Element) -> Void]? = nil,
        clean: [String]? = nil
    ) {
        self.selectors = selectors
        self.defaultCleaner = defaultCleaner
        self.allowMultiple = allowMultiple
        self.transforms = transforms
        self.clean = clean
    }
}

/// Represents a CSS selector for content extraction.
public enum Selector: Sendable {
    /// A simple CSS selector that extracts text content.
    case css(String)

    /// A CSS selector that extracts an attribute value.
    case cssWithAttribute(String, attribute: String)

    /// A CSS selector that extracts an attribute and transforms it.
    case cssWithTransform(String, attribute: String, transform: @Sendable (String) -> String)

    /// Multiple CSS selectors that must all match (for content extraction).
    case multiple([String])
}
