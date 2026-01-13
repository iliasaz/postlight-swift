import Foundation

/// The generic/fallback extractor that works with any website.
///
/// This extractor uses heuristics and scoring algorithms to identify
/// the main content of an article when no site-specific extractor matches.
public struct GenericExtractor: Extractor, Sendable {
    public let domain = "*"

    public init() {}

    // The generic extractor doesn't use selector-based configs.
    // Instead, it uses algorithmic extraction methods.
}

// MARK: - Generic Extraction Methods

extension GenericExtractor {
    /// Extracts content from a document using the generic algorithm.
    public func extract(document: Document, url: URL, options: ParserOptions) async throws -> ParsedArticle {
        let metaCache = try document.metaNames()

        // Extract all fields
        let title = try extractTitle(document: document, url: url)
        let author = try extractAuthor(document: document, metaCache: metaCache)
        let datePublished = try extractDatePublished(document: document, metaCache: metaCache)
        let content = try extractContent(document: document, title: title, url: url)
        let leadImageURL = try extractLeadImageURL(document: document, content: content)
        let dek = try extractDek(document: document, content: content)
        let excerpt = try extractExcerpt(document: document, content: content)
        let wordCount = extractWordCount(content: content)
        let direction = extractDirection(title: title)
        let (canonicalURL, domain) = try extractURLAndDomain(document: document, url: url)

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

    // MARK: - Individual Extractors

    func extractTitle(document: Document, url: URL) throws -> String? {
        // Try Open Graph title first
        if let ogTitle = try document.meta(property: "og:title"), !ogTitle.isEmpty {
            return cleanTitle(ogTitle, url: url)
        }

        // Try Twitter title
        if let twitterTitle = try document.meta(name: "twitter:title"), !twitterTitle.isEmpty {
            return cleanTitle(twitterTitle, url: url)
        }

        // Try standard meta title
        if let metaTitle = try document.meta(name: "title"), !metaTitle.isEmpty {
            return cleanTitle(metaTitle, url: url)
        }

        // Try document title
        if let docTitle = document.title, !docTitle.isEmpty {
            return cleanTitle(docTitle, url: url)
        }

        // Try h1 tags
        if let h1 = try document.selectFirst("h1")?.text(), !h1.isEmpty {
            return cleanTitle(h1, url: url)
        }

        return nil
    }

    func extractAuthor(document: Document, metaCache: [String]) throws -> String? {
        // Try various meta tags
        let authorMeta = ["author", "byl", "dc.creator", "article:author"]
        for name in authorMeta {
            if let author = try document.meta(name: name), !author.isEmpty {
                return cleanAuthor(author)
            }
        }

        // Try Open Graph
        if let author = try document.meta(property: "article:author"), !author.isEmpty {
            return cleanAuthor(author)
        }

        // Try common selectors
        let authorSelectors = [
            ".author",
            ".byline",
            "[rel='author']",
            "[itemprop='author']",
            ".post-author",
        ]

        for selector in authorSelectors {
            if let authorElement = try document.selectFirst(selector) {
                let text = try authorElement.text()
                if !text.isEmpty {
                    return cleanAuthor(text)
                }
            }
        }

        return nil
    }

    func extractDatePublished(document: Document, metaCache: [String]) throws -> Date? {
        // Try various meta tags
        let dateMeta = [
            "article:published_time",
            "article:published",
            "og:published_time",
            "date",
            "pubdate",
            "publish_date",
            "dc.date.issued",
        ]

        for name in dateMeta {
            if let dateStr = try document.meta(name: name) ?? document.meta(property: name), !dateStr.isEmpty {
                if let date = parseDate(dateStr) {
                    return date
                }
            }
        }

        // Try time elements
        if let timeElement = try document.selectFirst("time[datetime]") {
            if let datetime = timeElement.attrOrNil("datetime"), let date = parseDate(datetime) {
                return date
            }
        }

        return nil
    }

    func extractContent(document: Document, title: String?, url: URL) throws -> String? {
        // This will delegate to the ContentExtractor
        // For now, return a placeholder
        let contentExtractor = ContentExtractor()
        return try contentExtractor.extract(document: document, title: title, url: url)
    }

    func extractLeadImageURL(document: Document, content: String?) throws -> URL? {
        // Try Open Graph image
        if let ogImage = try document.meta(property: "og:image"), !ogImage.isEmpty {
            return URL(string: ogImage)
        }

        // Try Twitter image
        if let twitterImage = try document.meta(name: "twitter:image"), !twitterImage.isEmpty {
            return URL(string: twitterImage)
        }

        // Try to find first significant image in content
        // (This would analyze the content HTML for images)

        return nil
    }

    func extractDek(document: Document, content: String?) throws -> String? {
        // Try Open Graph description
        if let ogDesc = try document.meta(property: "og:description"), !ogDesc.isEmpty {
            return ogDesc
        }

        // Try meta description
        if let metaDesc = try document.meta(name: "description"), !metaDesc.isEmpty {
            return metaDesc
        }

        return nil
    }

    func extractExcerpt(document: Document, content: String?) throws -> String? {
        // Extract first paragraph or portion of content
        guard let content = content, !content.isEmpty else { return nil }

        // Parse content HTML and extract text
        let excerptDoc = try Document(html: content)
        let text = try excerptDoc.text()

        // Return first 200 characters
        if text.count > 200 {
            let index = text.index(text.startIndex, offsetBy: 200)
            return String(text[..<index]) + "..."
        }

        return text.isEmpty ? nil : text
    }

    func extractWordCount(content: String?) -> Int {
        guard let content = content, !content.isEmpty else { return 0 }

        // Strip HTML and count words
        let stripped = content.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )

        let words = stripped.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        return words.count
    }

    func extractDirection(title: String?) -> TextDirection {
        guard let title = title, !title.isEmpty else { return .leftToRight }

        // Check for RTL characters
        let rtlRanges: [ClosedRange<UnicodeScalar>] = [
            "\u{0590}"..."\u{05FF}", // Hebrew
            "\u{0600}"..."\u{06FF}", // Arabic
            "\u{0750}"..."\u{077F}", // Arabic Supplement
            "\u{FB50}"..."\u{FDFF}", // Arabic Presentation Forms-A
            "\u{FE70}"..."\u{FEFF}", // Arabic Presentation Forms-B
        ]

        var rtlCount = 0
        var ltrCount = 0

        for scalar in title.unicodeScalars {
            if rtlRanges.contains(where: { $0.contains(scalar) }) {
                rtlCount += 1
            } else if scalar.properties.isAlphabetic {
                ltrCount += 1
            }
        }

        return rtlCount > ltrCount ? .rightToLeft : .leftToRight
    }

    func extractURLAndDomain(document: Document, url: URL) throws -> (URL?, String) {
        // Try canonical URL
        if let canonical = try document.selectFirst("link[rel='canonical']")?.attrOrNil("href"),
           let canonicalURL = URL(string: canonical) {
            return (canonicalURL, canonicalURL.host ?? url.host ?? "")
        }

        // Try Open Graph URL
        if let ogURL = try document.meta(property: "og:url"),
           let ogURLParsed = URL(string: ogURL) {
            return (ogURLParsed, ogURLParsed.host ?? url.host ?? "")
        }

        return (url, url.host ?? "")
    }

    // MARK: - Cleaning Helpers

    private func cleanTitle(_ title: String, url: URL) -> String {
        var cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove site name suffix (e.g., " | Site Name" or " - Site Name")
        let separators = [" | ", " - ", " :: ", " / ", " – ", " — "]
        for separator in separators {
            if let range = cleaned.range(of: separator, options: .backwards) {
                let suffix = String(cleaned[range.upperBound...])
                // If suffix looks like a site name (short and matches domain), remove it
                if suffix.count < 50, url.host?.lowercased().contains(suffix.lowercased()) == true {
                    cleaned = String(cleaned[..<range.lowerBound])
                }
            }
        }

        return cleaned
    }

    private func cleanAuthor(_ author: String) -> String {
        var cleaned = author.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove "By " prefix
        let byPrefixes = ["By ", "by ", "BY "]
        for prefix in byPrefixes {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseDate(_ string: String) -> Date? {
        let formatters: [ISO8601DateFormatter] = {
            let full = ISO8601DateFormatter()
            full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]

            let dateOnly = ISO8601DateFormatter()
            dateOnly.formatOptions = [.withFullDate]

            return [full, standard, dateOnly]
        }()

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }

        // Try common date formats
        let dateFormatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "MMMM d, yyyy",
            "d MMMM yyyy",
        ]

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: string) {
                return date
            }
        }

        return nil
    }
}
