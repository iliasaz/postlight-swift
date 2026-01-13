import Foundation

/// Extracts next page URLs from multi-page articles.
///
/// Uses various heuristics to identify pagination links:
/// - rel="next" links
/// - Links with "next", "continue", or page numbers
/// - Common pagination patterns
public struct NextPageExtractor: Sendable {
    public init() {}

    /// Extracts the next page URL from a document.
    ///
    /// - Parameters:
    ///   - document: The HTML document to search.
    ///   - currentURL: The current page URL for resolving relative links.
    /// - Returns: The URL of the next page, or nil if not found.
    public func extract(document: Document, currentURL: URL) throws -> URL? {
        // Try rel="next" first (most reliable)
        if let nextURL = try extractRelNext(document: document, baseURL: currentURL) {
            return nextURL
        }

        // Try common pagination patterns
        if let nextURL = try extractPaginationLink(document: document, baseURL: currentURL) {
            return nextURL
        }

        // Try numbered pagination
        if let nextURL = try extractNumberedPagination(document: document, baseURL: currentURL) {
            return nextURL
        }

        return nil
    }

    // MARK: - rel="next" Extraction

    private func extractRelNext(document: Document, baseURL: URL) throws -> URL? {
        // Look for <link rel="next"> in head
        if let linkNext = try document.selectFirst("link[rel='next']"),
           let href = linkNext.attrOrNil("href"),
           let url = URL(string: href, relativeTo: baseURL) {
            return url
        }

        // Look for <a rel="next">
        if let aNext = try document.selectFirst("a[rel='next']"),
           let href = aNext.attrOrNil("href"),
           let url = URL(string: href, relativeTo: baseURL) {
            return url
        }

        return nil
    }

    // MARK: - Pagination Link Patterns

    /// Selectors for common pagination patterns.
    private let paginationSelectors = [
        // Class/ID based
        "a.next",
        "a.next-page",
        "a.nextpage",
        ".next a",
        ".pagination .next a",
        ".pagination-next a",
        "#pagination .next a",
        ".nav-next a",
        ".post-nav-next a",

        // Aria label based
        "a[aria-label='Next']",
        "a[aria-label='Next Page']",
        "a[aria-label*='next']",

        // Title based
        "a[title='Next']",
        "a[title='Next Page']",
        "a[title*='next']",
    ]

    private func extractPaginationLink(document: Document, baseURL: URL) throws -> URL? {
        for selector in paginationSelectors {
            if let element = try document.selectFirst(selector),
               let href = element.attrOrNil("href"),
               !href.isEmpty,
               href != "#",
               let url = URL(string: href, relativeTo: baseURL) {
                return url
            }
        }

        // Look for links containing "next" text
        let links = try document.select("a")
        for link in links {
            let text = try link.text().lowercased()
            let className = link.className?.lowercased() ?? ""

            // Check if link text indicates "next"
            if text == "next" || text == "next »" || text == "next ›" ||
               text == "» next" || text == "› next" ||
               text.contains("next page") || text.contains("continue reading") {
                if let href = link.attrOrNil("href"),
                   !href.isEmpty,
                   href != "#",
                   let url = URL(string: href, relativeTo: baseURL) {
                    return url
                }
            }

            // Check class name
            if className.contains("next") && !className.contains("prev") {
                if let href = link.attrOrNil("href"),
                   !href.isEmpty,
                   href != "#",
                   let url = URL(string: href, relativeTo: baseURL) {
                    return url
                }
            }
        }

        return nil
    }

    // MARK: - Numbered Pagination

    private func extractNumberedPagination(document: Document, baseURL: URL) throws -> URL? {
        // Get current page number from URL
        guard let currentPage = extractPageNumber(from: baseURL) else {
            return nil
        }

        let nextPage = currentPage + 1

        // Look for links to next page number
        let links = try document.select("a")
        for link in links {
            if let href = link.attrOrNil("href"),
               !href.isEmpty,
               let url = URL(string: href, relativeTo: baseURL),
               let linkPage = extractPageNumber(from: url),
               linkPage == nextPage {
                return url
            }
        }

        // Try to construct next page URL
        if let nextURL = constructNextPageURL(from: baseURL, nextPage: nextPage) {
            return nextURL
        }

        return nil
    }

    /// Extracts page number from a URL.
    private func extractPageNumber(from url: URL) -> Int? {
        let path = url.path
        let query = url.query ?? ""

        // Check path for /page/N or /p/N patterns
        let pathPatterns = [
            /\/page\/(\d+)/,
            /\/p\/(\d+)/,
            /\/(\d+)\/?$/,
            /-page-(\d+)/,
            /_page_(\d+)/,
        ]

        for pattern in pathPatterns {
            if let match = path.firstMatch(of: pattern) {
                return Int(match.1)
            }
        }

        // Check query parameters
        let queryPatterns = [
            /page=(\d+)/,
            /p=(\d+)/,
            /pg=(\d+)/,
            /pn=(\d+)/,
        ]

        for pattern in queryPatterns {
            if let match = query.firstMatch(of: pattern) {
                return Int(match.1)
            }
        }

        return nil
    }

    /// Constructs the next page URL by incrementing the page number.
    private func constructNextPageURL(from url: URL, nextPage: Int) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        guard var queryItems = components?.queryItems else {
            return nil
        }

        // Check for page query parameter
        for (index, item) in queryItems.enumerated() {
            if item.name == "page" || item.name == "p" || item.name == "pg" {
                queryItems[index].value = String(nextPage)
                components?.queryItems = queryItems
                return components?.url
            }
        }

        return nil
    }

    /// Validates that a URL is likely a real next page.
    public func isValidNextPage(_ url: URL, currentURL: URL) -> Bool {
        // Must be same domain
        guard url.host == currentURL.host else {
            return false
        }

        // Should not link to the same page
        guard url.absoluteString != currentURL.absoluteString else {
            return false
        }

        // Should not be a fragment-only link
        guard url.path != currentURL.path || url.query != currentURL.query else {
            return false
        }

        return true
    }
}
