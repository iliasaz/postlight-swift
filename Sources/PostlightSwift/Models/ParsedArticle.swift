import Foundation

/// Represents the direction of text in the extracted content.
public enum TextDirection: String, Codable, Sendable {
    case leftToRight = "ltr"
    case rightToLeft = "rtl"
}

/// The result of parsing a web article.
///
/// Contains all extracted metadata and content from a URL, including
/// title, author, publication date, main content, and more.
public struct ParsedArticle: Codable, Sendable, Equatable {
    /// The article's title.
    public let title: String?

    /// The main content of the article (HTML, Markdown, or plain text depending on options).
    public let content: String?

    /// The article's author(s).
    public let author: String?

    /// The publication date of the article.
    public let datePublished: Date?

    /// URL of the article's lead/featured image.
    public let leadImageURL: URL?

    /// A brief summary or deck (subheadline) of the article.
    public let dek: String?

    /// A short excerpt from the article content.
    public let excerpt: String?

    /// Word count of the main content.
    public let wordCount: Int

    /// Text direction (left-to-right or right-to-left).
    public let direction: TextDirection

    /// The canonical URL of the article.
    public let url: URL

    /// The domain of the article's URL.
    public let domain: String

    /// URL of the next page if the article spans multiple pages.
    public let nextPageURL: URL?

    /// Total number of pages for multi-page articles.
    public let totalPages: Int

    /// Number of pages that were actually rendered/fetched.
    public let renderedPages: Int

    /// Any additional extended extraction results.
    public let extended: [String: String]?

    /// Creates a new ParsedArticle with all fields.
    public init(
        title: String? = nil,
        content: String? = nil,
        author: String? = nil,
        datePublished: Date? = nil,
        leadImageURL: URL? = nil,
        dek: String? = nil,
        excerpt: String? = nil,
        wordCount: Int = 0,
        direction: TextDirection = .leftToRight,
        url: URL,
        domain: String,
        nextPageURL: URL? = nil,
        totalPages: Int = 1,
        renderedPages: Int = 1,
        extended: [String: String]? = nil
    ) {
        self.title = title
        self.content = content
        self.author = author
        self.datePublished = datePublished
        self.leadImageURL = leadImageURL
        self.dek = dek
        self.excerpt = excerpt
        self.wordCount = wordCount
        self.direction = direction
        self.url = url
        self.domain = domain
        self.nextPageURL = nextPageURL
        self.totalPages = totalPages
        self.renderedPages = renderedPages
        self.extended = extended
    }

    // Custom coding keys for JSON serialization matching the original JS output
    private enum CodingKeys: String, CodingKey {
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
        case extended
    }
}
