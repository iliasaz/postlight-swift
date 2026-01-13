import XCTest
@testable import PostlightSwift

final class ParserTests: XCTestCase {
    var parser: Parser!

    override func setUp() async throws {
        parser = Parser()
    }

    // MARK: - URL Validation Tests

    func testInvalidURLThrowsError() async throws {
        do {
            _ = try await parser.parse(url: URL(string: "not-a-url")!)
            XCTFail("Expected error for invalid URL")
        } catch let error as ParserError {
            if case .invalidURL = error {
                // Expected
            } else {
                XCTFail("Expected invalidURL error, got \(error)")
            }
        }
    }

    func testURLWithoutSchemeThrowsError() async throws {
        do {
            _ = try await parser.parse(url: URL(string: "example.com/article")!)
            XCTFail("Expected error for URL without scheme")
        } catch let error as ParserError {
            if case .invalidURL = error {
                // Expected
            } else {
                XCTFail("Expected invalidURL error, got \(error)")
            }
        }
    }

    // MARK: - HTML Parsing Tests

    func testParseSimpleHTML() async throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test Article</title>
            <meta property="og:title" content="Test Article Title">
            <meta name="author" content="John Doe">
        </head>
        <body>
            <article>
                <h1>Test Article Title</h1>
                <p>This is the first paragraph of the article. It contains some interesting content that we want to extract.</p>
                <p>This is the second paragraph with more content. The article continues with additional information.</p>
                <p>And here is a third paragraph to ensure we have enough content for the extraction algorithm.</p>
            </article>
        </body>
        </html>
        """

        let url = URL(string: "https://example.com/article")!
        let article = try await parser.parse(html: html, url: url)

        XCTAssertEqual(article.title, "Test Article Title")
        XCTAssertEqual(article.author, "John Doe")
        XCTAssertNotNil(article.content)
        XCTAssertEqual(article.domain, "example.com")
        XCTAssertEqual(article.url.absoluteString, "https://example.com/article")
    }

    func testParseWithOpenGraphMetadata() async throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta property="og:title" content="OG Title">
            <meta property="og:description" content="OG Description">
            <meta property="og:image" content="https://example.com/image.jpg">
            <meta property="article:published_time" content="2024-01-15T10:30:00Z">
        </head>
        <body>
            <article>
                <p>Article content goes here with enough text to be extracted properly by the algorithm.</p>
                <p>More content to ensure the extraction works correctly and produces valid output.</p>
            </article>
        </body>
        </html>
        """

        let url = URL(string: "https://example.com/article")!
        let article = try await parser.parse(html: html, url: url)

        XCTAssertEqual(article.title, "OG Title")
        XCTAssertEqual(article.dek, "OG Description")
        XCTAssertEqual(article.leadImageURL?.absoluteString, "https://example.com/image.jpg")
    }

    // MARK: - Content Type Tests

    func testMarkdownContentType() async throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>Test</title></head>
        <body>
            <article>
                <h2>Section Header</h2>
                <p>This is <strong>bold</strong> and <em>italic</em> text.</p>
                <p>Here is a <a href="https://example.com">link</a>.</p>
            </article>
        </body>
        </html>
        """

        let url = URL(string: "https://example.com/article")!
        let options = ParserOptions(contentType: .markdown)
        let article = try await parser.parse(html: html, url: url, options: options)

        XCTAssertNotNil(article.content)
        // Content should contain markdown formatting
        if let content = article.content {
            XCTAssertTrue(content.contains("**") || content.contains("*"), "Content should contain markdown formatting")
        }
    }

    func testTextContentType() async throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>Test</title></head>
        <body>
            <article>
                <p>This is plain text content.</p>
                <p>Second paragraph.</p>
            </article>
        </body>
        </html>
        """

        let url = URL(string: "https://example.com/article")!
        let options = ParserOptions(contentType: .text)
        let article = try await parser.parse(html: html, url: url, options: options)

        XCTAssertNotNil(article.content)
        if let content = article.content {
            // Content should not contain HTML tags
            XCTAssertFalse(content.contains("<p>"), "Content should not contain HTML tags")
            XCTAssertFalse(content.contains("</p>"), "Content should not contain HTML tags")
        }
    }

    // MARK: - Word Count Tests

    func testWordCount() async throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>Test</title></head>
        <body>
            <article>
                <p>One two three four five six seven eight nine ten.</p>
            </article>
        </body>
        </html>
        """

        let url = URL(string: "https://example.com/article")!
        let article = try await parser.parse(html: html, url: url)

        XCTAssertGreaterThan(article.wordCount, 0)
    }

    // MARK: - Direction Tests

    func testLeftToRightDirection() async throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>English Title</title></head>
        <body>
            <article>
                <p>English content here.</p>
            </article>
        </body>
        </html>
        """

        let url = URL(string: "https://example.com/article")!
        let article = try await parser.parse(html: html, url: url)

        XCTAssertEqual(article.direction, .leftToRight)
    }
}
