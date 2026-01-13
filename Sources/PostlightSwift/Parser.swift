import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The main entry point for parsing web articles.
///
/// The Parser extracts article content and metadata from any URL,
/// using site-specific extractors when available and falling back
/// to generic extraction algorithms otherwise.
///
/// ## Example Usage
///
/// ```swift
/// let parser = Parser()
/// let article = try await parser.parse(url: URL(string: "https://example.com/article")!)
/// print(article.title)
/// print(article.content)
/// ```
public actor Parser {
    /// The HTTP client used for fetching resources.
    private let httpClient: HTTPClient

    /// The extractor registry for finding site-specific extractors.
    private let extractorRegistry: ExtractorRegistry

    /// Creates a new Parser instance.
    /// - Parameter httpClient: Custom HTTP client. Uses default if not provided.
    public init(httpClient: HTTPClient? = nil) {
        self.httpClient = httpClient ?? DefaultHTTPClient()
        self.extractorRegistry = ExtractorRegistry.shared
    }

    /// Parses an article from a URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the article to parse.
    ///   - options: Parser options for customizing extraction.
    /// - Returns: The parsed article with extracted content and metadata.
    /// - Throws: `ParserError` if parsing fails.
    public func parse(url: URL, options: ParserOptions = .default) async throws -> ParsedArticle {
        // Validate URL
        guard isValidURL(url) else {
            throw ParserError.invalidURL(url.absoluteString)
        }

        // Fetch resource
        let (data, response) = try await fetchResource(url: url, headers: options.headers)

        // Create document with proper encoding detection
        let encoding = extractEncoding(from: response, data: data)
        let document = try Document(data: data, encoding: encoding, baseURL: url)

        // Get appropriate extractor
        let extractor: any Extractor
        if let custom = options.customExtractor {
            extractor = custom
        } else {
            extractor = await extractorRegistry.getExtractor(for: url, document: document)
        }

        // Extract content
        var result = try await extract(
            document: document,
            extractor: extractor,
            url: url,
            options: options
        )

        // Handle multi-page articles
        if options.fetchAllPages, let nextPageURL = result.nextPageURL {
            result = try await collectAllPages(
                initialResult: result,
                nextPageURL: nextPageURL,
                extractor: extractor,
                options: options
            )
        }

        // Convert content format if needed
        if options.contentType != .html, let content = result.content {
            let convertedContent = convertContent(content, to: options.contentType)
            result = ParsedArticle(
                title: result.title,
                content: convertedContent,
                author: result.author,
                datePublished: result.datePublished,
                leadImageURL: result.leadImageURL,
                dek: result.dek,
                excerpt: result.excerpt,
                wordCount: result.wordCount,
                direction: result.direction,
                url: result.url,
                domain: result.domain,
                nextPageURL: result.nextPageURL,
                totalPages: result.totalPages,
                renderedPages: result.renderedPages,
                extended: result.extended
            )
        }

        return result
    }

    /// Parses an article from pre-fetched HTML.
    ///
    /// - Parameters:
    ///   - html: The HTML content to parse.
    ///   - url: The URL of the article (used for link resolution and extractor matching).
    ///   - options: Parser options for customizing extraction.
    /// - Returns: The parsed article with extracted content and metadata.
    /// - Throws: `ParserError` if parsing fails.
    public func parse(html: String, url: URL, options: ParserOptions = .default) async throws -> ParsedArticle {
        let document = try Document(html: html, baseURL: url)

        let extractor: any Extractor
        if let custom = options.customExtractor {
            extractor = custom
        } else {
            extractor = await extractorRegistry.getExtractor(for: url, document: document)
        }

        var result = try await extract(
            document: document,
            extractor: extractor,
            url: url,
            options: options
        )

        if options.contentType != .html, let content = result.content {
            let convertedContent = convertContent(content, to: options.contentType)
            result = ParsedArticle(
                title: result.title,
                content: convertedContent,
                author: result.author,
                datePublished: result.datePublished,
                leadImageURL: result.leadImageURL,
                dek: result.dek,
                excerpt: result.excerpt,
                wordCount: result.wordCount,
                direction: result.direction,
                url: result.url,
                domain: result.domain,
                nextPageURL: result.nextPageURL,
                totalPages: result.totalPages,
                renderedPages: result.renderedPages,
                extended: result.extended
            )
        }

        return result
    }

    /// Adds a custom extractor to the registry.
    ///
    /// Custom extractors take precedence over built-in extractors.
    /// - Parameter extractor: The extractor to add.
    public func addExtractor(_ extractor: any Extractor) async {
        await extractorRegistry.addCustomExtractor(extractor)
    }

    // MARK: - Private Methods

    private func isValidURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return ["http", "https"].contains(scheme) && url.host != nil
    }

    private func fetchResource(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        try await httpClient.fetch(url: url, headers: headers)
    }

    private func extractEncoding(from response: HTTPURLResponse, data: Data? = nil) -> String.Encoding? {
        let contentType = response.value(forHTTPHeaderField: "Content-Type")
        let detector = EncodingDetector()

        // If we have data, use full detection
        if let data = data {
            return detector.detect(data: data, contentType: contentType)
        }

        // Otherwise just parse Content-Type header
        guard let contentType = contentType else {
            return nil
        }

        return detector.encoding(fromName: contentType)
    }

    private func extract(
        document: Document,
        extractor: any Extractor,
        url: URL,
        options: ParserOptions
    ) async throws -> ParsedArticle {
        // Use the generic extractor's algorithm
        // Site-specific extractors will use selector-based extraction
        if extractor.domain == "*" {
            let genericExtractor = GenericExtractor()
            return try await genericExtractor.extract(document: document, url: url, options: options)
        }

        // For site-specific extractors, use selector-based extraction
        return try await extractWithSelectors(
            document: document,
            extractor: extractor,
            url: url,
            options: options
        )
    }

    private func extractWithSelectors(
        document: Document,
        extractor: any Extractor,
        url: URL,
        options: ParserOptions
    ) async throws -> ParsedArticle {
        // Try to extract using the site-specific extractor's selectors
        // Fall back to generic extraction if needed

        let title = try extractField(document: document, config: extractor.titleConfig)
            ?? (options.fallback ? GenericExtractor().extractTitle(document: document, url: url) : nil)

        let author = try extractField(document: document, config: extractor.authorConfig)
            ?? (options.fallback ? GenericExtractor().extractAuthor(document: document, metaCache: document.metaNames()) : nil)

        let datePublished: Date? = nil // TODO: Implement date extraction with selectors

        let content = try extractHTMLField(document: document, config: extractor.contentConfig)
            ?? (options.fallback ? GenericExtractor().extractContent(document: document, title: title, url: url) : nil)

        let leadImageStr = try extractField(document: document, config: extractor.leadImageConfig)
        let leadImageURL = leadImageStr.flatMap { URL(string: $0) }

        let dek = try extractField(document: document, config: extractor.dekConfig)
        let excerpt = try extractField(document: document, config: extractor.excerptConfig)

        let wordCount = GenericExtractor().extractWordCount(content: content)
        let direction = GenericExtractor().extractDirection(title: title)
        let (canonicalURL, domain) = try GenericExtractor().extractURLAndDomain(document: document, url: url)

        return ParsedArticle(
            title: title,
            content: content,
            author: author,
            datePublished: datePublished,
            leadImageURL: leadImageURL,
            dek: dek,
            excerpt: excerpt,
            wordCount: wordCount,
            direction: direction,
            url: canonicalURL ?? url,
            domain: domain,
            nextPageURL: nil,
            totalPages: 1,
            renderedPages: 1
        )
    }

    private func extractField(document: Document, config: ExtractionConfig?) throws -> String? {
        guard let config = config else { return nil }

        for selector in config.selectors {
            switch selector {
            case .css(let cssSelector):
                if let element = try document.selectFirst(cssSelector) {
                    let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        return text
                    }
                }

            case .cssWithAttribute(let cssSelector, let attribute):
                if let element = try document.selectFirst(cssSelector),
                   let value = element.attrOrNil(attribute)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !value.isEmpty {
                    return value
                }

            case .cssWithTransform(let cssSelector, let attribute, let transform):
                if let element = try document.selectFirst(cssSelector),
                   let value = element.attrOrNil(attribute) {
                    return transform(value)
                }

            case .multiple:
                // Multiple selectors are for HTML content extraction
                continue
            }
        }

        return nil
    }

    private func extractHTMLField(document: Document, config: ExtractionConfig?) throws -> String? {
        guard let config = config else { return nil }

        for selector in config.selectors {
            switch selector {
            case .css(let cssSelector):
                if let element = try document.selectFirst(cssSelector) {
                    return try element.html()
                }

            case .multiple(let selectors):
                var combinedHTML = ""
                var allFound = true
                for cssSelector in selectors {
                    if let element = try document.selectFirst(cssSelector) {
                        combinedHTML += try element.html()
                    } else {
                        allFound = false
                        break
                    }
                }
                if allFound && !combinedHTML.isEmpty {
                    return combinedHTML
                }

            default:
                continue
            }
        }

        return nil
    }

    private func collectAllPages(
        initialResult: ParsedArticle,
        nextPageURL: URL,
        extractor: any Extractor,
        options: ParserOptions
    ) async throws -> ParsedArticle {
        var combinedContent = initialResult.content ?? ""
        var currentURL = nextPageURL
        var pageCount = 1
        let maxPages = 25 // Safety limit

        while pageCount < maxPages {
            let (data, response) = try await fetchResource(url: currentURL, headers: options.headers)
            let encoding = extractEncoding(from: response)
            let document = try Document(data: data, encoding: encoding, baseURL: currentURL)

            let pageResult = try await extract(
                document: document,
                extractor: extractor,
                url: currentURL,
                options: options
            )

            if let content = pageResult.content {
                combinedContent += content
            }

            pageCount += 1

            guard let nextURL = pageResult.nextPageURL else {
                break
            }
            currentURL = nextURL
        }

        return ParsedArticle(
            title: initialResult.title,
            content: combinedContent,
            author: initialResult.author,
            datePublished: initialResult.datePublished,
            leadImageURL: initialResult.leadImageURL,
            dek: initialResult.dek,
            excerpt: initialResult.excerpt,
            wordCount: GenericExtractor().extractWordCount(content: combinedContent),
            direction: initialResult.direction,
            url: initialResult.url,
            domain: initialResult.domain,
            nextPageURL: nil,
            totalPages: pageCount,
            renderedPages: pageCount
        )
    }

    private func convertContent(_ html: String, to contentType: ContentType) -> String {
        switch contentType {
        case .html:
            return html

        case .markdown:
            let converter = HTMLToMarkdown()
            do {
                return try converter.convert(html)
            } catch {
                // Fall back to basic regex conversion on error
                return basicHTMLToMarkdown(html)
            }

        case .text:
            let converter = HTMLToText()
            do {
                return try converter.convert(html)
            } catch {
                // Fall back to basic regex conversion on error
                return basicHTMLToText(html)
            }
        }
    }

    /// Basic fallback HTML to Markdown conversion using regex.
    private func basicHTMLToMarkdown(_ html: String) -> String {
        var markdown = html

        // Headers
        markdown = markdown.replacingOccurrences(of: "<h1[^>]*>(.*?)</h1>", with: "# $1\n\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "<h2[^>]*>(.*?)</h2>", with: "## $1\n\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "<h3[^>]*>(.*?)</h3>", with: "### $1\n\n", options: .regularExpression)

        // Bold and italic
        markdown = markdown.replacingOccurrences(of: "<strong[^>]*>(.*?)</strong>", with: "**$1**", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "<b[^>]*>(.*?)</b>", with: "**$1**", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "<em[^>]*>(.*?)</em>", with: "*$1*", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "<i[^>]*>(.*?)</i>", with: "*$1*", options: .regularExpression)

        // Links
        markdown = markdown.replacingOccurrences(of: "<a[^>]*href=\"([^\"]+)\"[^>]*>(.*?)</a>", with: "[$2]($1)", options: .regularExpression)

        // Paragraphs and line breaks
        markdown = markdown.replacingOccurrences(of: "<p[^>]*>(.*?)</p>", with: "$1\n\n", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)

        // Remove remaining tags
        markdown = markdown.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Clean up whitespace
        markdown = markdown.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)

        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Basic fallback HTML to plain text conversion using regex.
    private func basicHTMLToText(_ html: String) -> String {
        var text = html

        // Replace block elements with newlines
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</h[1-6]>", with: "\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)

        // Remove all tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode HTML entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")

        // Clean up whitespace
        text = text.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - HTTP Client Protocol

/// Protocol for HTTP clients used by the parser.
public protocol HTTPClient: Sendable {
    /// Fetches a resource from a URL.
    /// - Parameters:
    ///   - url: The URL to fetch.
    ///   - headers: Additional HTTP headers.
    /// - Returns: The response data and HTTP response.
    func fetch(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse)
}

// MARK: - Default HTTP Client

/// Default HTTP client implementation using URLSession.
public struct DefaultHTTPClient: HTTPClient, Sendable {
    /// Default request headers.
    private static let defaultHeaders: [String: String] = [
        "User-Agent": "Mozilla/5.0 (compatible; PostlightParser/1.0)",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
    ]

    /// Request timeout in seconds.
    private static let timeout: TimeInterval = 30

    /// Maximum content length (10 MB).
    private static let maxContentLength = 10 * 1024 * 1024

    public init() {}

    public func fetch(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        request.httpMethod = "GET"

        // Set default headers
        for (key, value) in Self.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set custom headers (override defaults)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ParserError.fetchFailed(message: "Invalid response type")
        }

        // Check status code
        guard httpResponse.statusCode == 200 else {
            throw ParserError.httpError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }

        // Check content type
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
            let lowercased = contentType.lowercased()
            if !lowercased.contains("html") && !lowercased.contains("text") {
                throw ParserError.unsupportedContentType(contentType)
            }
        }

        // Check content length
        if data.count > Self.maxContentLength {
            throw ParserError.contentTooLarge(size: data.count, maxSize: Self.maxContentLength)
        }

        return (data, httpResponse)
    }
}
