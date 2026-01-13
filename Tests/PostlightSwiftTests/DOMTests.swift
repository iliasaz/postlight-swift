import XCTest
@testable import PostlightSwift

final class DOMTests: XCTestCase {
    // MARK: - Document Tests

    func testParseSimpleHTML() throws {
        let html = "<html><head><title>Test</title></head><body><p>Hello</p></body></html>"
        let doc = try Document(html: html)

        XCTAssertEqual(doc.title, "Test")
        XCTAssertTrue(doc.hasChildren)
    }

    func testSelectElements() throws {
        let html = """
        <html>
        <body>
            <div class="container">
                <p class="intro">First paragraph</p>
                <p class="content">Second paragraph</p>
            </div>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        let paragraphs = try doc.select("p")

        XCTAssertEqual(paragraphs.count, 2)
        XCTAssertEqual(try paragraphs[0].text(), "First paragraph")
        XCTAssertEqual(try paragraphs[1].text(), "Second paragraph")
    }

    func testSelectFirst() throws {
        let html = """
        <html>
        <body>
            <h1>Title</h1>
            <p>Content</p>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        let h1 = try doc.selectFirst("h1")

        XCTAssertNotNil(h1)
        XCTAssertEqual(try h1?.text(), "Title")
    }

    func testSelectMissing() throws {
        let html = "<html><body><p>Hello</p></body></html>"
        let doc = try Document(html: html)
        let missing = try doc.selectFirst("h1")

        XCTAssertNil(missing)
    }

    // MARK: - Element Tests

    func testElementAttributes() throws {
        let html = """
        <html>
        <body>
            <a href="https://example.com" class="link" id="main-link">Link</a>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        let link = try doc.selectFirst("a")!

        XCTAssertEqual(try link.attr("href"), "https://example.com")
        XCTAssertEqual(link.className, "link")
        XCTAssertEqual(link.id, "main-link")
        XCTAssertEqual(link.tagName, "a")
    }

    func testElementText() throws {
        let html = """
        <html>
        <body>
            <p>Hello <strong>World</strong></p>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        let p = try doc.selectFirst("p")!

        XCTAssertEqual(try p.text(), "Hello World")
    }

    func testElementHtml() throws {
        let html = """
        <html>
        <body>
            <p>Hello <strong>World</strong></p>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        let p = try doc.selectFirst("p")!
        let innerHtml = try p.html()

        XCTAssertTrue(innerHtml.contains("<strong>"))
        XCTAssertTrue(innerHtml.contains("World"))
    }

    func testElementParent() throws {
        let html = """
        <html>
        <body>
            <div class="container">
                <p>Content</p>
            </div>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        let p = try doc.selectFirst("p")!
        let parent = p.parent()

        XCTAssertNotNil(parent)
        XCTAssertEqual(parent?.tagName, "div")
        XCTAssertEqual(parent?.className, "container")
    }

    func testElementChildren() throws {
        let html = """
        <html>
        <body>
            <ul>
                <li>One</li>
                <li>Two</li>
                <li>Three</li>
            </ul>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        let ul = try doc.selectFirst("ul")!
        let children = ul.children()

        XCTAssertEqual(children.count, 3)
        XCTAssertEqual(try children[0].text(), "One")
        XCTAssertEqual(try children[1].text(), "Two")
        XCTAssertEqual(try children[2].text(), "Three")
    }

    func testElementRemove() throws {
        let html = """
        <html>
        <body>
            <div>
                <p class="keep">Keep this</p>
                <p class="remove">Remove this</p>
            </div>
        </body>
        </html>
        """

        let doc = try Document(html: html)
        let toRemove = try doc.selectFirst("p.remove")!
        try toRemove.remove()

        let remaining = try doc.select("p")
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].className, "keep")
    }

    // MARK: - Meta Tag Tests

    func testMetaTags() throws {
        let html = """
        <html>
        <head>
            <meta name="author" content="John Doe">
            <meta property="og:title" content="OG Title">
        </head>
        <body></body>
        </html>
        """

        let doc = try Document(html: html)

        XCTAssertEqual(try doc.meta(name: "author"), "John Doe")
        XCTAssertEqual(try doc.meta(property: "og:title"), "OG Title")
    }

    func testMetaNames() throws {
        let html = """
        <html>
        <head>
            <meta name="author" content="John">
            <meta name="description" content="Test">
            <meta property="og:title" content="Title">
        </head>
        <body></body>
        </html>
        """

        let doc = try Document(html: html)
        let names = try doc.metaNames()

        XCTAssertTrue(names.contains("author"))
        XCTAssertTrue(names.contains("description"))
    }

    // MARK: - Scoring Tests

    func testElementScore() throws {
        let html = "<html><body><p>Test</p></body></html>"
        let doc = try Document(html: html)
        let p = try doc.selectFirst("p")!

        // Initial score should be 0
        XCTAssertEqual(p.score, 0)

        // Set score
        p.score = 25.5
        XCTAssertEqual(p.score, 25.5)

        // Add to score
        p.score += 10
        XCTAssertEqual(p.score, 35.5)
    }
}
