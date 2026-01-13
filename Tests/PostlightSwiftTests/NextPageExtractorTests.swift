import XCTest
@testable import PostlightSwift

final class NextPageExtractorTests: XCTestCase {
    var extractor: NextPageExtractor!

    override func setUp() {
        extractor = NextPageExtractor()
    }

    // MARK: - rel="next" Tests

    func testExtractRelNextLink() throws {
        let html = """
        <html>
        <head>
            <link rel="next" href="/article?page=2">
        </head>
        <body>
            <p>Content here</p>
        </body>
        </html>
        """

        let doc = try Document(html: html, baseURL: URL(string: "https://example.com/article")!)
        let nextURL = try extractor.extract(document: doc, currentURL: URL(string: "https://example.com/article")!)

        XCTAssertNotNil(nextURL)
        XCTAssertTrue(nextURL?.absoluteString.contains("page=2") ?? false)
    }

    func testExtractRelNextAnchor() throws {
        let html = """
        <html>
        <body>
            <a rel="next" href="/article/page/2">Next</a>
        </body>
        </html>
        """

        let doc = try Document(html: html, baseURL: URL(string: "https://example.com/article")!)
        let nextURL = try extractor.extract(document: doc, currentURL: URL(string: "https://example.com/article")!)

        XCTAssertNotNil(nextURL)
        XCTAssertTrue(nextURL?.absoluteString.contains("page/2") ?? false)
    }

    // MARK: - Class-based Navigation Tests

    func testExtractNextClass() throws {
        let html = """
        <html>
        <body>
            <div class="pagination">
                <a class="prev" href="/article?page=1">Previous</a>
                <a class="next" href="/article?page=3">Next</a>
            </div>
        </body>
        </html>
        """

        let doc = try Document(html: html, baseURL: URL(string: "https://example.com/article?page=2")!)
        let nextURL = try extractor.extract(document: doc, currentURL: URL(string: "https://example.com/article?page=2")!)

        XCTAssertNotNil(nextURL)
        XCTAssertTrue(nextURL?.absoluteString.contains("page=3") ?? false)
    }

    // MARK: - Text-based Navigation Tests

    func testExtractNextText() throws {
        let html = """
        <html>
        <body>
            <nav>
                <a href="/article?page=1">Previous</a>
                <a href="/article?page=3">Next</a>
            </nav>
        </body>
        </html>
        """

        let doc = try Document(html: html, baseURL: URL(string: "https://example.com/article?page=2")!)
        let nextURL = try extractor.extract(document: doc, currentURL: URL(string: "https://example.com/article?page=2")!)

        XCTAssertNotNil(nextURL)
        XCTAssertTrue(nextURL?.absoluteString.contains("page=3") ?? false)
    }

    // MARK: - Edge Cases

    func testNoNextPage() throws {
        let html = """
        <html>
        <body>
            <p>Article content without pagination</p>
        </body>
        </html>
        """

        let doc = try Document(html: html, baseURL: URL(string: "https://example.com/article")!)
        let nextURL = try extractor.extract(document: doc, currentURL: URL(string: "https://example.com/article")!)

        XCTAssertNil(nextURL)
    }

    func testIgnoreHashLinks() throws {
        let html = """
        <html>
        <body>
            <a class="next" href="#">Next</a>
        </body>
        </html>
        """

        let doc = try Document(html: html, baseURL: URL(string: "https://example.com/article")!)
        let nextURL = try extractor.extract(document: doc, currentURL: URL(string: "https://example.com/article")!)

        XCTAssertNil(nextURL)
    }

    // MARK: - Validation Tests

    func testIsValidNextPage() {
        let currentURL = URL(string: "https://example.com/article")!

        // Same domain is valid
        let sameHost = URL(string: "https://example.com/article?page=2")!
        XCTAssertTrue(extractor.isValidNextPage(sameHost, currentURL: currentURL))

        // Different domain is invalid
        let differentHost = URL(string: "https://other.com/article")!
        XCTAssertFalse(extractor.isValidNextPage(differentHost, currentURL: currentURL))

        // Same URL is invalid
        XCTAssertFalse(extractor.isValidNextPage(currentURL, currentURL: currentURL))
    }
}
