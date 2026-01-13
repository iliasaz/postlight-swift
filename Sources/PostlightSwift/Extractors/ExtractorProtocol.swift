import Foundation

/// Protocol that all content extractors must conform to.
///
/// Extractors define how to extract article metadata and content from
/// specific domains. The generic extractor (`*` domain) is used as a
/// fallback when no site-specific extractor matches.
public protocol Extractor: Sendable {
    /// The domain this extractor handles (e.g., "www.nytimes.com").
    /// Use "*" for the generic/fallback extractor.
    var domain: String { get }

    /// Configuration for extracting the article title.
    var titleConfig: ExtractionConfig? { get }

    /// Configuration for extracting the author name(s).
    var authorConfig: ExtractionConfig? { get }

    /// Configuration for extracting the publication date.
    var datePublishedConfig: ExtractionConfig? { get }

    /// Configuration for extracting the main content.
    var contentConfig: ExtractionConfig? { get }

    /// Configuration for extracting the lead/featured image URL.
    var leadImageConfig: ExtractionConfig? { get }

    /// Configuration for extracting the deck/subheadline.
    var dekConfig: ExtractionConfig? { get }

    /// Configuration for extracting the excerpt.
    var excerptConfig: ExtractionConfig? { get }

    /// Configuration for extracting the next page URL.
    var nextPageConfig: ExtractionConfig? { get }
}

// MARK: - Default implementations

extension Extractor {
    public var titleConfig: ExtractionConfig? { nil }
    public var authorConfig: ExtractionConfig? { nil }
    public var datePublishedConfig: ExtractionConfig? { nil }
    public var contentConfig: ExtractionConfig? { nil }
    public var leadImageConfig: ExtractionConfig? { nil }
    public var dekConfig: ExtractionConfig? { nil }
    public var excerptConfig: ExtractionConfig? { nil }
    public var nextPageConfig: ExtractionConfig? { nil }
}

// MARK: - Extractor Registry

/// Registry for managing site-specific extractors.
public actor ExtractorRegistry {
    /// Shared instance of the extractor registry.
    public static let shared = ExtractorRegistry()

    /// Built-in extractors indexed by domain.
    private var extractors: [String: any Extractor] = [:]

    /// Custom extractors added at runtime.
    private var customExtractors: [String: any Extractor] = [:]

    private init() {
        // Register built-in extractors
        registerBuiltInExtractors()
    }

    /// Registers built-in site-specific extractors.
    private func registerBuiltInExtractors() {
        // Will be populated with custom extractors
        // e.g., register(NYTimesExtractor())
    }

    /// Registers an extractor for its domain.
    public func register(_ extractor: any Extractor) {
        extractors[extractor.domain] = extractor
    }

    /// Adds a custom extractor (takes precedence over built-in).
    public func addCustomExtractor(_ extractor: any Extractor) {
        customExtractors[extractor.domain] = extractor
    }

    /// Gets the appropriate extractor for a URL.
    ///
    /// Lookup order:
    /// 1. Custom extractors (exact hostname match)
    /// 2. Custom extractors (base domain match)
    /// 3. Built-in extractors (exact hostname match)
    /// 4. Built-in extractors (base domain match)
    /// 5. HTML-based detection
    /// 6. Generic extractor (fallback)
    public func getExtractor(for url: URL, document: Document? = nil) -> any Extractor {
        guard let host = url.host else {
            return GenericExtractor()
        }

        let baseDomain = extractBaseDomain(from: host)

        // Check custom extractors first
        if let extractor = customExtractors[host] ?? customExtractors[baseDomain] {
            return extractor
        }

        // Check built-in extractors
        if let extractor = extractors[host] ?? extractors[baseDomain] {
            return extractor
        }

        // Try HTML-based detection if document is available
        if let document = document, let extractor = detectByHTML(document) {
            return extractor
        }

        // Fall back to generic extractor
        return GenericExtractor()
    }

    /// Extracts base domain from hostname (e.g., "www.example.com" -> "example.com").
    private func extractBaseDomain(from host: String) -> String {
        let components = host.split(separator: ".")
        guard components.count >= 2 else { return host }
        return components.suffix(2).joined(separator: ".")
    }

    /// Attempts to detect the appropriate extractor based on HTML content.
    private func detectByHTML(_ document: Document) -> (any Extractor)? {
        // Check for WordPress
        if document.isWordPress {
            return nil // Use generic for WordPress (it handles it well)
        }

        // Add more HTML-based detection as needed
        return nil
    }
}
