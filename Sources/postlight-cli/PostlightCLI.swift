import ArgumentParser
import Foundation
import PostlightSwift

/// Command-line interface for the Postlight Parser.
///
/// Usage:
///   postlight-cli <url> [options]
///
/// Examples:
///   postlight-cli https://example.com/article
///   postlight-cli https://example.com/article --format markdown
///   postlight-cli https://example.com/article --header "User-Agent=MyBot"
@main
struct PostlightCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "postlight-cli",
        abstract: "Extract article content from any URL.",
        discussion: """
            The Postlight Parser extracts semantic content from any URL, including:
            - Article title and content
            - Author and publication date
            - Lead image URL
            - Excerpt and word count

            Results are output as JSON.
            """,
        version: PostlightSwift.version
    )

    // MARK: - Arguments

    @Argument(help: "The URL to parse.")
    var url: String

    // MARK: - Options

    @Option(name: [.short, .long], help: "Output format: html, markdown, or text.")
    var format: String = "html"

    @Option(name: [.customShort("H"), .long], help: "HTTP header in the format 'Name=Value'. Can be specified multiple times.")
    var header: [String] = []

    @Option(name: [.short, .long], help: "Extended extraction in the format 'name=selector'. Can be specified multiple times.")
    var extend: [String] = []

    @Option(name: [.customShort("l"), .long], help: "Extended list extraction in the format 'name=selector'. Can be specified multiple times.")
    var extendList: [String] = []

    @Flag(name: [.short, .long], help: "Show verbose output.")
    var verbose: Bool = false

    // MARK: - Run

    func run() async throws {
        // Validate URL
        guard let parsedURL = URL(string: url), parsedURL.scheme != nil, parsedURL.host != nil else {
            throw ValidationError("Invalid URL: \(url)")
        }

        // Parse format
        let contentType: ContentType
        switch format.lowercased() {
        case "html":
            contentType = .html
        case "markdown", "md":
            contentType = .markdown
        case "text", "txt":
            contentType = .text
        default:
            throw ValidationError("Invalid format '\(format)'. Use: html, markdown, or text.")
        }

        // Parse headers
        var headers: [String: String] = [:]
        for h in header {
            let parts = h.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else {
                throw ValidationError("Invalid header format '\(h)'. Use: Name=Value")
            }
            headers[String(parts[0])] = String(parts[1])
        }

        // Parse extended extraction
        var extensions: [String: ExtractionConfig] = [:]
        for e in extend {
            let parts = e.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else {
                throw ValidationError("Invalid extend format '\(e)'. Use: name=selector")
            }
            let name = String(parts[0])
            let selectorStr = String(parts[1])
            let selector: Selector
            if selectorStr.contains("|") {
                let selectorParts = selectorStr.split(separator: "|")
                selector = .cssWithAttribute(String(selectorParts[0]), attribute: String(selectorParts[1]))
            } else {
                selector = .css(selectorStr)
            }
            extensions[name] = ExtractionConfig(selectors: [selector])
        }

        for e in extendList {
            let parts = e.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else {
                throw ValidationError("Invalid extend-list format '\(e)'. Use: name=selector")
            }
            let name = String(parts[0])
            let selectorStr = String(parts[1])
            let selector: Selector
            if selectorStr.contains("|") {
                let selectorParts = selectorStr.split(separator: "|")
                selector = .cssWithAttribute(String(selectorParts[0]), attribute: String(selectorParts[1]))
            } else {
                selector = .css(selectorStr)
            }
            extensions[name] = ExtractionConfig(selectors: [selector], allowMultiple: true)
        }

        // Create parser options
        let options = ParserOptions(
            contentType: contentType,
            headers: headers,
            extend: extensions.isEmpty ? nil : extensions
        )

        // Parse
        if verbose {
            fputs("Parsing \(url)...\n", stderr)
        }

        let parser = Parser()

        do {
            let article = try await parser.parse(url: parsedURL, options: options)

            // Output as JSON
            let output = ArticleOutput(article: article)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(output)
            if let json = String(data: data, encoding: .utf8) {
                print(json)
            }
        } catch {
            // Output error as JSON
            let errorOutput = ErrorOutput(error: true, message: error.localizedDescription)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            if let data = try? encoder.encode(errorOutput),
               let json = String(data: data, encoding: .utf8) {
                print(json)
            }

            if verbose {
                fputs("\nError: \(error)\n", stderr)
                fputs("\nIf you believe this was an error, please file an issue at:\n", stderr)
                fputs("    https://github.com/postlight/parser/issues/new\n", stderr)
            }

            throw ExitCode.failure
        }
    }
}

// MARK: - Output Types

/// JSON output structure for successful parsing.
private struct ArticleOutput: Encodable {
    let title: String?
    let content: String?
    let author: String?
    let datePublished: String?
    let leadImageURL: String?
    let dek: String?
    let excerpt: String?
    let wordCount: Int
    let direction: String
    let url: String
    let domain: String
    let nextPageURL: String?
    let totalPages: Int
    let renderedPages: Int

    init(article: ParsedArticle) {
        self.title = article.title
        self.content = article.content
        self.author = article.author
        self.datePublished = article.datePublished?.ISO8601Format()
        self.leadImageURL = article.leadImageURL?.absoluteString
        self.dek = article.dek
        self.excerpt = article.excerpt
        self.wordCount = article.wordCount
        self.direction = article.direction.rawValue
        self.url = article.url.absoluteString
        self.domain = article.domain
        self.nextPageURL = article.nextPageURL?.absoluteString
        self.totalPages = article.totalPages
        self.renderedPages = article.renderedPages
    }

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case author
        case datePublished = "date_published"
        case leadImageURL = "lead_image_url"
        case dek
        case excerpt
        case wordCount = "word_count"
        case direction
        case url
        case domain
        case nextPageURL = "next_page_url"
        case totalPages = "total_pages"
        case renderedPages = "rendered_pages"
    }
}

/// JSON output structure for errors.
private struct ErrorOutput: Encodable {
    let error: Bool
    let message: String
}
