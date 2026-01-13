import XCTest
@testable import PostlightSwift

final class HTMLPreprocessorTests: XCTestCase {
    var preprocessor: HTMLPreprocessor!

    override func setUp() {
        preprocessor = HTMLPreprocessor()
    }

    // MARK: - Lazy Image Tests

    func testConvertLazyImages() throws {
        let html = """
        <html>
        <body>
            <img data-src="https://example.com/real-image.jpg" src="placeholder.gif">
        </body>
        </html>
        """

        let doc = try Document(html: html)
        _ = try preprocessor.preprocess(doc)

        let img = try doc.selectFirst("img")
        let src = try img?.attr("src")

        XCTAssertEqual(src, "https://example.com/real-image.jpg")
    }

    func testConvertMultipleLazyImageAttributes() throws {
        let html = """
        <html>
        <body>
            <img data-lazy-src="https://example.com/lazy.jpg" src="placeholder.gif">
            <img data-original="https://example.com/original.jpg" src="placeholder.gif">
        </body>
        </html>
        """

        let doc = try Document(html: html)
        _ = try preprocessor.preprocess(doc)

        let images = try doc.select("img")
        XCTAssertEqual(images.count, 2)

        let src1 = try images[0].attr("src")
        let src2 = try images[1].attr("src")

        XCTAssertTrue(src1.contains("lazy.jpg"))
        XCTAssertTrue(src2.contains("original.jpg"))
    }

    // MARK: - Script Removal Tests

    func testRemoveScripts() throws {
        let html = """
        <html>
        <body>
            <p>Content</p>
            <script>alert('test');</script>
            <p>More content</p>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        _ = try preprocessor.preprocess(doc)

        let scripts = try doc.select("script")
        XCTAssertEqual(scripts.count, 0)

        let paragraphs = try doc.select("p")
        XCTAssertEqual(paragraphs.count, 2)
    }

    func testRemoveStyles() throws {
        let html = """
        <html>
        <head>
            <style>body { color: red; }</style>
        </head>
        <body>
            <p>Content</p>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        _ = try preprocessor.preprocess(doc)

        let styles = try doc.select("style")
        XCTAssertEqual(styles.count, 0)
    }

    // MARK: - URL Normalization Tests

    func testMakeURLsAbsolute() throws {
        let html = """
        <html>
        <body>
            <a href="/page">Link</a>
            <img src="/image.jpg">
        </body>
        </html>
        """

        let baseURL = URL(string: "https://example.com/article")!
        let doc = try Document(html: html, baseURL: baseURL)
        try preprocessor.makeURLsAbsolute(doc, baseURL: baseURL)

        let link = try doc.selectFirst("a")
        let href = try link?.attr("href")
        XCTAssertEqual(href, "https://example.com/page")

        let img = try doc.selectFirst("img")
        let src = try img?.attr("src")
        XCTAssertEqual(src, "https://example.com/image.jpg")
    }

    func testPreserveAbsoluteURLs() throws {
        let html = """
        <html>
        <body>
            <a href="https://other.com/page">External Link</a>
            <a href="//cdn.example.com/file">Protocol-relative</a>
        </body>
        </html>
        """

        let baseURL = URL(string: "https://example.com/article")!
        let doc = try Document(html: html, baseURL: baseURL)
        try preprocessor.makeURLsAbsolute(doc, baseURL: baseURL)

        let links = try doc.select("a")
        let href1 = try links[0].attr("href")
        let href2 = try links[1].attr("href")

        XCTAssertEqual(href1, "https://other.com/page")
        XCTAssertEqual(href2, "//cdn.example.com/file")
    }

    func testIgnoreSpecialURLs() throws {
        let html = """
        <html>
        <body>
            <a href="#">Hash link</a>
            <a href="javascript:void(0)">JS link</a>
            <a href="mailto:test@example.com">Email</a>
        </body>
        </html>
        """

        let baseURL = URL(string: "https://example.com/article")!
        let doc = try Document(html: html, baseURL: baseURL)
        try preprocessor.makeURLsAbsolute(doc, baseURL: baseURL)

        let links = try doc.select("a")

        // These should remain unchanged
        XCTAssertEqual(try links[0].attr("href"), "#")
        XCTAssertEqual(try links[1].attr("href"), "javascript:void(0)")
        XCTAssertEqual(try links[2].attr("href"), "mailto:test@example.com")
    }
}
