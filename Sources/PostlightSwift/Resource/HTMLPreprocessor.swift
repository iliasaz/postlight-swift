import Foundation

/// Preprocesses HTML documents before content extraction.
///
/// This utility handles:
/// - Converting lazy-loaded images to standard images
/// - Normalizing noscript content
/// - Removing scripts and styles
/// - Fixing common HTML issues
public struct HTMLPreprocessor: Sendable {
    public init() {}

    /// Preprocesses an HTML document for content extraction.
    ///
    /// - Parameter document: The document to preprocess.
    /// - Returns: The preprocessed document.
    public func preprocess(_ document: Document) throws -> Document {
        // Convert lazy images
        try convertLazyImages(document)

        // Process noscript tags
        try processNoscriptTags(document)

        // Remove unwanted elements
        try removeUnwantedElements(document)

        // Normalize whitespace in text nodes
        try normalizeWhitespace(document)

        return document
    }

    // MARK: - Lazy Image Conversion

    /// Common data attributes used for lazy loading images.
    private let lazyImageAttributes = [
        "data-src",
        "data-lazy-src",
        "data-original",
        "data-srcset",
        "data-lazy-srcset",
        "data-original-set",
        "data-hi-res-src",
        "data-full-src",
        "data-image",
        "data-img-src",
    ]

    private func convertLazyImages(_ document: Document) throws {
        let images = try document.select("img")

        for img in images {
            // Check for lazy loading attributes
            for attr in lazyImageAttributes {
                if let lazySrc = img.attrOrNil(attr), !lazySrc.isEmpty {
                    // Set the src attribute
                    try img.attr("src", lazySrc)

                    // Handle srcset
                    if attr.contains("srcset"), img.attrOrNil("srcset") == nil {
                        try img.attr("srcset", lazySrc)
                    }

                    break
                }
            }

            // Check for srcset variations
            if let dataSrcset = img.attrOrNil("data-srcset"),
               img.attrOrNil("srcset") == nil {
                try img.attr("srcset", dataSrcset)
            }

            // Remove placeholder classes
            if img.hasClass("lazy") {
                try img.removeClass("lazy")
            }
            if img.hasClass("lazyload") {
                try img.removeClass("lazyload")
            }
        }

        // Handle background images in data attributes
        let elementsWithBg = try document.select("[data-background], [data-bg]")
        for element in elementsWithBg {
            if let bgSrc = element.attrOrNil("data-background") ?? element.attrOrNil("data-bg"),
               !bgSrc.isEmpty {
                // Could add inline style, but typically we just note the URL
                // For extraction purposes, we mainly care about img tags
            }
        }
    }

    // MARK: - Noscript Processing

    private func processNoscriptTags(_ document: Document) throws {
        let noscripts = try document.select("noscript")

        for noscript in noscripts {
            // Check if noscript contains an image (common for lazy loading fallbacks)
            let html = try noscript.html()
            if html.contains("<img") {
                // Replace the noscript with its content
                try noscript.replaceWith(html)
            }
        }
    }

    // MARK: - Remove Unwanted Elements

    /// Tags to remove during preprocessing.
    private let removeTagSelectors = [
        "script",
        "style",
        "link[rel='stylesheet']",
        "noscript:empty",
        "iframe[src*='ads']",
        "iframe[src*='analytics']",
        "object",
        "embed",
        "svg[class*='icon']",
        "[aria-hidden='true']",
        ".hidden",
        "[style*='display: none']",
        "[style*='display:none']",
    ]

    private func removeUnwantedElements(_ document: Document) throws {
        for selector in removeTagSelectors {
            let elements = try document.select(selector)
            for element in elements {
                try element.remove()
            }
        }

        // Remove empty paragraphs
        let paragraphs = try document.select("p")
        for p in paragraphs {
            let text = try p.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty && p.children().isEmpty {
                try p.remove()
            }
        }
    }

    // MARK: - Whitespace Normalization

    private func normalizeWhitespace(_ document: Document) throws {
        // This is handled by SwiftSoup during parsing, but we can
        // ensure consistent spacing in text content

        // Remove excessive breaks
        let breaks = try document.select("br + br + br")
        for br in breaks {
            try br.remove()
        }
    }

    // MARK: - URL Normalization

    /// Makes all relative URLs absolute.
    ///
    /// - Parameters:
    ///   - document: The document to process.
    ///   - baseURL: The base URL for resolution.
    public func makeURLsAbsolute(_ document: Document, baseURL: URL) throws {
        // Process links
        let links = try document.select("a[href]")
        for link in links {
            if let href = link.attrOrNil("href"),
               !href.hasPrefix("http"),
               !href.hasPrefix("//"),
               !href.hasPrefix("#"),
               !href.hasPrefix("javascript:"),
               !href.hasPrefix("mailto:"),
               let absoluteURL = URL(string: href, relativeTo: baseURL) {
                try link.attr("href", absoluteURL.absoluteString)
            }
        }

        // Process images
        let images = try document.select("img[src]")
        for img in images {
            if let src = img.attrOrNil("src"),
               !src.hasPrefix("http"),
               !src.hasPrefix("//"),
               !src.hasPrefix("data:"),
               let absoluteURL = URL(string: src, relativeTo: baseURL) {
                try img.attr("src", absoluteURL.absoluteString)
            }
        }

        // Process source elements (for picture/video)
        let sources = try document.select("source[src], source[srcset]")
        for source in sources {
            if let src = source.attrOrNil("src"),
               !src.hasPrefix("http"),
               !src.hasPrefix("//"),
               let absoluteURL = URL(string: src, relativeTo: baseURL) {
                try source.attr("src", absoluteURL.absoluteString)
            }
        }
    }
}
