# Postlight Parser - JavaScript to Swift Translation Plan

## Executive Summary

This document outlines a comprehensive plan for translating the Postlight Parser (formerly Mercury Parser) from JavaScript to Swift. The goal is to maintain the original architecture and design patterns while leveraging Swift's type safety, memory safety, and performance characteristics. The library will support both Apple platforms (macOS, iOS) and Linux.

---

## 1. Original Architecture Analysis

### 1.1 Core Components

The Postlight Parser consists of the following main modules:

| Module | Purpose | JavaScript Location |
|--------|---------|---------------------|
| **Parser** | Main entry point, orchestrates extraction | `src/mercury.js` |
| **Resource** | Fetches and prepares HTML documents | `src/resource/` |
| **Extractors** | Domain-specific and generic content extraction | `src/extractors/` |
| **Cleaners** | Post-processing and content cleanup | `src/cleaners/` |
| **Utils** | DOM manipulation, text processing, scoring | `src/utils/` |

### 1.2 Data Flow

```
URL Input
    │
    ▼
┌─────────────────────┐
│  Resource.create()  │  ← Fetch HTML, decode encoding, normalize
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  getExtractor()     │  ← Match domain to custom or generic extractor
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  RootExtractor      │  ← Extract title, author, date, content, etc.
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  Cleaners           │  ← Clean and normalize extracted content
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  Output Conversion  │  ← HTML, Markdown, or Plain Text
└─────────────────────┘
    │
    ▼
ParsedArticle Result
```

### 1.3 Key Algorithms

1. **Content Scoring Algorithm** - Scores DOM nodes based on:
   - Text density (commas, sentence length)
   - CSS class/ID hints (positive: "article", "content"; negative: "sidebar", "comment")
   - hNews/microformat selectors
   - Parent/child relationship scoring

2. **Candidate Elimination** - Removes unlikely content candidates based on blacklist patterns

3. **Best Node Selection** - Finds highest-scoring content node, merges relevant siblings

4. **Content Cleaning** - Removes ads, navigation, scripts, styles, empty elements

---

## 2. Swift Architecture Design

### 2.1 Package Structure

```
PostlightSwift/
├── Package.swift
├── Sources/
│   ├── PostlightSwift/           # Main library
│   │   ├── Parser.swift          # Main API entry point
│   │   ├── Models/
│   │   │   ├── ParsedArticle.swift
│   │   │   ├── ParserOptions.swift
│   │   │   ├── ParserError.swift
│   │   │   └── ContentType.swift
│   │   ├── Resource/
│   │   │   ├── ResourceFetcher.swift
│   │   │   ├── EncodingDetector.swift
│   │   │   └── HTMLPreprocessor.swift
│   │   ├── Extractors/
│   │   │   ├── ExtractorProtocol.swift
│   │   │   ├── ExtractorRegistry.swift
│   │   │   ├── GenericExtractor/
│   │   │   │   ├── GenericExtractor.swift
│   │   │   │   ├── TitleExtractor.swift
│   │   │   │   ├── AuthorExtractor.swift
│   │   │   │   ├── DateExtractor.swift
│   │   │   │   ├── ContentExtractor.swift
│   │   │   │   ├── LeadImageExtractor.swift
│   │   │   │   ├── ExcerptExtractor.swift
│   │   │   │   └── WordCountExtractor.swift
│   │   │   ├── Scoring/
│   │   │   │   ├── ContentScorer.swift
│   │   │   │   ├── NodeScorer.swift
│   │   │   │   ├── WeightCalculator.swift
│   │   │   │   └── ScoringConstants.swift
│   │   │   └── Custom/
│   │   │       ├── NYTimesExtractor.swift
│   │   │       ├── MediumExtractor.swift
│   │   │       ├── WikipediaExtractor.swift
│   │   │       └── ... (145+ site-specific extractors)
│   │   ├── Cleaners/
│   │   │   ├── ContentCleaner.swift
│   │   │   ├── TitleCleaner.swift
│   │   │   ├── AuthorCleaner.swift
│   │   │   ├── DateCleaner.swift
│   │   │   └── ImageCleaner.swift
│   │   ├── DOM/
│   │   │   ├── Document.swift        # HTML parsing wrapper
│   │   │   ├── Element.swift         # DOM element abstraction
│   │   │   ├── Selector.swift        # CSS selector support
│   │   │   ├── DOMTransforms.swift
│   │   │   └── DOMCleanup.swift
│   │   ├── Utils/
│   │   │   ├── URLValidator.swift
│   │   │   ├── TextNormalizer.swift
│   │   │   ├── DateParser.swift
│   │   │   └── StringDirection.swift
│   │   └── Extensions/
│   │       ├── String+Utilities.swift
│   │       ├── URL+Utilities.swift
│   │       └── Data+Encoding.swift
│   └── postlight-cli/                # CLI utility
│       └── PostlightCLI.swift
├── Tests/
│   └── PostlightSwiftTests/
│       ├── ParserTests.swift
│       ├── ExtractorTests/
│       ├── CleanerTests/
│       ├── ScoringTests/
│       ├── DOMTests/
│       └── Fixtures/                 # HTML test fixtures
└── .github/
    └── workflows/
        └── ci.yml
```

### 2.2 Core Type Definitions

```swift
// Models/ParsedArticle.swift
public struct ParsedArticle: Codable, Sendable {
    public let title: String?
    public let content: String?
    public let author: String?
    public let datePublished: Date?
    public let leadImageURL: URL?
    public let dek: String?
    public let excerpt: String?
    public let wordCount: Int
    public let direction: TextDirection
    public let url: URL
    public let domain: String
    public let nextPageURL: URL?
    public let totalPages: Int
    public let renderedPages: Int
}

// Models/ParserOptions.swift
public struct ParserOptions: Sendable {
    public var fetchAllPages: Bool = true
    public var fallback: Bool = true
    public var contentType: ContentType = .html
    public var headers: [String: String] = [:]
    public var customExtractor: (any Extractor)?
    public var extend: [String: ExtractionConfig]?
}

// Models/ContentType.swift
public enum ContentType: String, Sendable {
    case html
    case markdown
    case text
}

// Models/ParserError.swift
public enum ParserError: Error, LocalizedError {
    case invalidURL(String)
    case fetchFailed(underlying: Error)
    case parseError(String)
    case contentNotFound
    case encodingError
    case timeout
}
```

### 2.3 Protocol Definitions

```swift
// Extractors/ExtractorProtocol.swift
public protocol Extractor: Sendable {
    var domain: String { get }

    var titleConfig: ExtractionConfig? { get }
    var authorConfig: ExtractionConfig? { get }
    var datePublishedConfig: ExtractionConfig? { get }
    var contentConfig: ExtractionConfig? { get }
    var leadImageConfig: ExtractionConfig? { get }
    var dekConfig: ExtractionConfig? { get }
    var excerptConfig: ExtractionConfig? { get }
    var nextPageConfig: ExtractionConfig? { get }

    var transforms: [String: ElementTransform]? { get }
    var clean: [String]? { get }
}

public struct ExtractionConfig: Sendable {
    public let selectors: [Selector]
    public let defaultCleaner: Bool
    public let allowMultiple: Bool
    public let transforms: [String: ElementTransform]?
    public let clean: [String]?
}

public enum Selector: Sendable {
    case css(String)
    case cssWithAttribute(String, String)
    case cssWithAttributeAndTransform(String, String, (String) -> String)
    case multiple([String])
}
```

---

## 3. Dependencies and Cross-Platform Strategy

### 3.1 HTML Parsing

The original uses `cheerio` (jQuery-like) for HTML parsing. For Swift:

**Recommended: SwiftSoup**
- Pure Swift implementation
- Works on both Apple platforms and Linux
- jQuery-like API familiar to JS developers
- Active maintenance

```swift
// Package.swift dependency
.package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0")
```

### 3.2 HTTP Networking

**AsyncHTTPClient** (for Linux compatibility) + **URLSession** (for Apple platforms):

```swift
// Conditional compilation for cross-platform support
#if canImport(FoundationNetworking)
import FoundationNetworking  // Linux
#endif

// Use protocol abstraction
protocol HTTPClient: Sendable {
    func fetch(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse)
}
```

For Linux:
```swift
.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.19.0")
```

### 3.3 Markdown Conversion

**Recommended: SwiftMarkdownKit** or **Ink**

```swift
.package(url: "https://github.com/johnsundell/ink.git", from: "0.6.0")
```

### 3.4 Date Parsing

Custom implementation to match moment.js behavior:
- ISO 8601 parsing
- Relative time parsing ("2 hours ago")
- Multiple format detection
- Timezone handling

### 3.5 Character Encoding

Foundation's `String.Encoding` with fallback detection similar to `iconv-lite`.

### 3.6 Dependency Summary

| JavaScript | Swift Equivalent | Cross-Platform |
|------------|------------------|----------------|
| cheerio | SwiftSoup | Yes |
| postman-request | URLSession / AsyncHTTPClient | Yes |
| iconv-lite | Foundation String.Encoding | Yes |
| moment.js | Foundation Date + Custom Parser | Yes |
| turndown | swift-markdown / Ink | Yes |
| string-direction | Custom Implementation | Yes |
| valid-url | Foundation URL | Yes |
| wuzzy | Custom Implementation | Yes |
| difflib | Custom Implementation | Yes |

---

## 4. Implementation Phases

### Phase 1: Foundation (Week 1-2)

#### 4.1.1 Package Setup
- [ ] Create Package.swift with correct platform targets
- [ ] Set up directory structure
- [ ] Configure Swift 6 strict concurrency
- [ ] Add SwiftSoup dependency

#### 4.1.2 Core Models
- [ ] Implement `ParsedArticle`
- [ ] Implement `ParserOptions`
- [ ] Implement `ParserError`
- [ ] Implement `ContentType`

#### 4.1.3 DOM Abstraction Layer
- [ ] Create `Document` wrapper around SwiftSoup
- [ ] Create `Element` wrapper
- [ ] Implement CSS selector support
- [ ] Port DOM utility functions:
  - `convertNodeTo`
  - `makeLinksAbsolute`
  - `stripUnlikelyCandidates`
  - `convertToParagraphs`

### Phase 2: Resource Fetching (Week 2-3)

#### 4.2.1 HTTP Client
- [ ] Implement cross-platform HTTP client protocol
- [ ] Implement URLSession-based client (Apple)
- [ ] Implement AsyncHTTPClient-based client (Linux)
- [ ] Add request headers support
- [ ] Add timeout handling
- [ ] Add redirect following

#### 4.2.2 Resource Processing
- [ ] Implement encoding detection
- [ ] Implement HTML preprocessing
- [ ] Port lazy image conversion
- [ ] Port meta tag normalization

### Phase 3: Generic Extractor (Week 3-5)

#### 4.3.1 Scoring System
- [ ] Port scoring constants (blacklist, whitelist, hints)
- [ ] Implement `getWeight()` - class/ID scoring
- [ ] Implement `scoreCommas()` - comma density
- [ ] Implement `scoreLength()` - text length bonus
- [ ] Implement `scoreParagraph()` - paragraph scoring
- [ ] Implement `scoreContent()` - content tree scoring
- [ ] Implement `findTopCandidate()` - best node selection
- [ ] Implement `mergeSiblings()` - sibling merging

#### 4.3.2 Content Extraction
- [ ] Implement `stripUnlikelyCandidates()`
- [ ] Implement `convertToParagraphs()`
- [ ] Implement `extractBestNode()`
- [ ] Implement content cleaning pipeline

#### 4.3.3 Metadata Extractors
- [ ] Implement `TitleExtractor`
- [ ] Implement `AuthorExtractor`
- [ ] Implement `DateExtractor`
- [ ] Implement `LeadImageExtractor`
- [ ] Implement `ExcerptExtractor`
- [ ] Implement `DekExtractor`
- [ ] Implement `WordCountExtractor`
- [ ] Implement `DirectionExtractor`
- [ ] Implement `URLExtractor`

### Phase 4: Cleaners (Week 5-6)

#### 4.4.1 Content Cleaners
- [ ] Port `cleanContent()` - main content cleaner
- [ ] Port `cleanHOnes()` - H1 tag handling
- [ ] Port `cleanHeaders()` - header cleanup
- [ ] Port `cleanTags()` - conditional tag removal
- [ ] Port `cleanImages()` - image cleanup
- [ ] Port `removeEmpty()` - empty element removal
- [ ] Port `cleanAttributes()` - attribute stripping

#### 4.4.2 Metadata Cleaners
- [ ] Port `cleanTitle()` - title normalization
- [ ] Port `cleanAuthor()` - author string cleanup
- [ ] Port `cleanDatePublished()` - date parsing
- [ ] Port `cleanDek()` - dek cleanup
- [ ] Port `cleanLeadImageUrl()` - image URL validation

### Phase 5: Custom Extractors (Week 6-8)

#### 4.5.1 Extractor Infrastructure
- [ ] Implement `ExtractorRegistry`
- [ ] Implement `getExtractor()` domain matching
- [ ] Implement `detectByHtml()` fallback detection
- [ ] Implement `addCustomExtractor()` API

#### 4.5.2 High-Priority Custom Extractors (Top 30)
Port the most commonly used site-specific extractors:
- [ ] www.nytimes.com
- [ ] www.washingtonpost.com
- [ ] medium.com
- [ ] www.theguardian.com
- [ ] www.bbc.com
- [ ] www.cnn.com
- [ ] www.reuters.com
- [ ] www.bloomberg.com
- [ ] www.wsj.com
- [ ] techcrunch.com
- [ ] www.wired.com
- [ ] arstechnica.com
- [ ] www.theverge.com
- [ ] github.com
- [ ] stackoverflow.com
- [ ] wikipedia.org
- [ ] www.reddit.com
- [ ] www.youtube.com (metadata)
- [ ] twitter.com
- [ ] www.npr.org
- [ ] www.theatlantic.com
- [ ] www.newyorker.com
- [ ] www.economist.com
- [ ] www.forbes.com
- [ ] www.businessinsider.com
- [ ] mashable.com
- [ ] www.huffpost.com
- [ ] www.buzzfeed.com
- [ ] www.vox.com
- [ ] www.axios.com

#### 4.5.3 Remaining Custom Extractors
- [ ] Port remaining 115+ site-specific extractors
- [ ] Create code generation tool for bulk conversion

### Phase 6: Multi-Page Support (Week 8)

- [ ] Implement `collectAllPages()`
- [ ] Implement pagination detection
- [ ] Implement content merging

### Phase 7: Output Formatting (Week 8-9)

- [ ] Implement HTML output (default)
- [ ] Implement Markdown conversion
- [ ] Implement plain text conversion
- [ ] Implement text direction detection

### Phase 8: CLI Tool (Week 9)

- [ ] Set up ArgumentParser
- [ ] Implement URL parsing command
- [ ] Implement format options (--format)
- [ ] Implement header options (--header)
- [ ] Implement extend options (--extend)
- [ ] Implement custom extractor loading (--add-extractor)
- [ ] Implement JSON output
- [ ] Implement verbose mode

### Phase 9: Testing (Week 9-11)

#### 4.9.1 Unit Tests
- [ ] Parser API tests
- [ ] Scoring algorithm tests
- [ ] DOM manipulation tests
- [ ] Cleaner tests
- [ ] Date parsing tests
- [ ] URL validation tests

#### 4.9.2 Integration Tests
- [ ] Generic extractor tests
- [ ] Custom extractor tests per site
- [ ] Multi-page extraction tests
- [ ] Output format tests

#### 4.9.3 Fixture Migration
- [ ] Port HTML fixtures from JS tests
- [ ] Create Swift-native test helpers
- [ ] Implement fixture loading system

### Phase 10: CI/CD (Week 11)

- [ ] GitHub Actions workflow for macOS
- [ ] GitHub Actions workflow for Linux
- [ ] Test coverage reporting
- [ ] Automated release workflow

---

## 5. Swift-Specific Optimizations

### 5.1 Concurrency Model

Use Swift 6 structured concurrency throughout:

```swift
public actor Parser {
    private let httpClient: any HTTPClient
    private let extractorRegistry: ExtractorRegistry

    public func parse(url: URL, options: ParserOptions = .init()) async throws -> ParsedArticle {
        // Async/await for network calls
        let (data, response) = try await httpClient.fetch(url: url, headers: options.headers)

        // Parse and extract
        let document = try Document(data: data, encoding: response.encoding)
        let extractor = extractorRegistry.getExtractor(for: url, document: document)

        return try await extract(document: document, extractor: extractor, options: options)
    }
}
```

### 5.2 Memory Efficiency

- Use `Substring` instead of `String` where possible
- Implement lazy evaluation for DOM traversal
- Use copy-on-write for large data structures
- Pool regex patterns for reuse

### 5.3 Type Safety

```swift
// Strong typing for selectors
public enum SelectorResult {
    case text(String)
    case attribute(String, value: String)
    case html(String)
    case elements([Element])
}

// Type-safe extraction results
public struct ExtractionResult<T> {
    public let value: T?
    public let confidence: Double
    public let source: ExtractionSource
}
```

### 5.4 Error Handling

```swift
// Detailed error types
public enum ParserError: Error {
    case network(NetworkError)
    case parsing(ParsingError)
    case extraction(ExtractionError)
}

public enum NetworkError: Error {
    case invalidURL(String)
    case timeout(TimeInterval)
    case httpError(statusCode: Int, message: String)
    case connectionFailed(Error)
}

public enum ParsingError: Error {
    case invalidHTML
    case encodingDetectionFailed
    case emptyDocument
}
```

---

## 6. Test Strategy

### 6.1 Test Categories

1. **Unit Tests** - Individual function testing
2. **Integration Tests** - Component interaction testing
3. **Fixture Tests** - Real-world HTML parsing
4. **Performance Tests** - Benchmarking critical paths
5. **Snapshot Tests** - Output comparison

### 6.2 Fixture Migration

The original has 228 test files with HTML fixtures. Strategy:

```swift
// Tests/PostlightSwiftTests/Fixtures/
// Organize by domain
// nytimes.com/
//   article-standard.html
//   article-interactive.html
// medium.com/
//   post.html

final class NYTimesExtractorTests: XCTestCase {
    func testStandardArticle() async throws {
        let html = try loadFixture("nytimes.com/article-standard.html")
        let result = try await parser.parse(html: html, url: nytimesURL)

        XCTAssertEqual(result.title, "Expected Title")
        XCTAssertNotNil(result.content)
        XCTAssertEqual(result.author, "Expected Author")
    }
}
```

### 6.3 Test Parity Checklist

Mirror the JS test structure:
- [ ] `mercury.test.js` → `ParserTests.swift`
- [ ] `root-extractor.test.js` → `RootExtractorTests.swift`
- [ ] `get-extractor.test.js` → `ExtractorRegistryTests.swift`
- [ ] `score-content.test.js` → `ContentScorerTests.swift`
- [ ] `find-top-candidate.test.js` → `TopCandidateTests.swift`
- [ ] `clean-*.test.js` → `Cleaner*Tests.swift`
- [ ] Per-domain extractor tests (145+ test files)

---

## 7. GitHub Actions Configuration

### 7.1 CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-macos:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Build
        run: swift build -v

      - name: Run Tests
        run: swift test -v --parallel

      - name: Build Release
        run: swift build -c release

  test-linux:
    runs-on: ubuntu-latest
    container:
      image: swift:6.0-jammy
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: swift build -v

      - name: Run Tests
        run: swift test -v --parallel

      - name: Build Release
        run: swift build -c release

  lint:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: SwiftLint
        run: |
          brew install swiftlint
          swiftlint lint --strict

  build-cli:
    needs: [test-macos, test-linux]
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [macos-14, ubuntu-latest]
    steps:
      - uses: actions/checkout@v4

      - name: Build CLI
        run: swift build -c release --product postlight-cli

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: postlight-cli-${{ matrix.os }}
          path: .build/release/postlight-cli
```

### 7.2 Release Workflow

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Build Universal Binary
        run: |
          swift build -c release --arch arm64 --arch x86_64

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            .build/release/postlight-cli
          generate_release_notes: true
```

---

## 8. API Design

### 8.1 Basic Usage

```swift
import PostlightSwift

// Simple parsing
let parser = Parser()
let article = try await parser.parse(url: URL(string: "https://example.com/article")!)
print(article.title)
print(article.content)

// With options
let options = ParserOptions(
    contentType: .markdown,
    headers: ["User-Agent": "CustomBot/1.0"]
)
let article = try await parser.parse(url: url, options: options)

// Parse pre-fetched HTML
let article = try await parser.parse(html: htmlString, url: url)
```

### 8.2 Custom Extractors

```swift
// Define a custom extractor
struct MyBlogExtractor: Extractor {
    let domain = "myblog.com"

    var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [.css("h1.post-title")])
    }

    var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [.css("article.post-content")],
            clean: [".ad", ".related-posts"]
        )
    }

    // ... other configs
}

// Register and use
let parser = Parser()
parser.addExtractor(MyBlogExtractor())
```

### 8.3 CLI Usage

```bash
# Basic usage
postlight-cli https://example.com/article

# Markdown output
postlight-cli https://example.com/article --format markdown

# Custom headers
postlight-cli https://example.com/article --header "User-Agent=CustomBot"

# Extended extraction
postlight-cli https://example.com/article --extend "tags=.post-tags a"

# JSON output (default)
postlight-cli https://example.com/article | jq .title
```

---

## 9. Migration Considerations

### 9.1 Regex Pattern Translation

JavaScript regex patterns need conversion to Swift's `Regex` or `NSRegularExpression`:

```javascript
// JavaScript
const POSITIVE_SCORE_RE = new RegExp('article|content|post', 'i');
```

```swift
// Swift
let positiveScorePattern = /article|content|post/
    .ignoresCase()

// Or for runtime patterns
let positiveScoreRegex = try NSRegularExpression(
    pattern: "article|content|post",
    options: .caseInsensitive
)
```

### 9.2 DOM API Mapping

| cheerio (JS) | SwiftSoup (Swift) |
|--------------|-------------------|
| `$(selector)` | `try doc.select(selector)` |
| `$node.text()` | `try element.text()` |
| `$node.html()` | `try element.html()` |
| `$node.attr('href')` | `try element.attr("href")` |
| `$node.parent()` | `element.parent()` |
| `$node.children()` | `element.children()` |
| `$node.remove()` | `try element.remove()` |
| `$node.addClass('x')` | `try element.addClass("x")` |

### 9.3 Async/Callback Translation

```javascript
// JavaScript (callback-based)
request(options, (err, response, body) => {
    if (err) reject(err);
    else resolve({ body, response });
});
```

```swift
// Swift (async/await)
func fetch(url: URL) async throws -> (Data, URLResponse) {
    try await URLSession.shared.data(from: url)
}
```

---

## 10. Risk Assessment

### 10.1 Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SwiftSoup parsing differences | Medium | Medium | Extensive testing with fixtures |
| Linux platform issues | Medium | High | CI testing on Linux from day 1 |
| Date parsing edge cases | High | Low | Comprehensive date format tests |
| Encoding detection failures | Medium | Medium | Fallback encoding chain |
| Performance regression | Low | Medium | Benchmarking suite |

### 10.2 Schedule Risks

| Risk | Mitigation |
|------|------------|
| Custom extractor volume (145+) | Code generation tooling |
| Test fixture migration | Automated conversion script |
| Cross-platform compatibility | Early Linux CI integration |

---

## 11. Success Metrics

### 11.1 Functional Parity

- [ ] All 228 original tests passing
- [ ] All 145+ custom extractors ported
- [ ] CLI feature parity

### 11.2 Performance Targets

- Parse time: ≤ JavaScript implementation
- Memory usage: ≤ JavaScript implementation
- Binary size (CLI): < 20MB

### 11.3 Quality Metrics

- Test coverage: > 80%
- No compiler warnings
- Swift 6 strict concurrency compliance
- SwiftLint clean

---

## 12. Appendix

### A. Scoring Constants Reference

```swift
// From constants.js - to be ported
let unlikelyCandidatesBlacklist = [
    "ad-break", "adbox", "advert", "addthis", "agegate", "aux",
    "blogger-labels", "combx", "comment", "conversation", "disqus",
    "entry-unrelated", "extra", "foot", "form", "header", "hidden",
    "loader", "login", "menu", "meta", "nav", "pager", "pagination",
    "predicta", "presence_control_external", "popup", "printfriendly",
    "related", "remove", "remark", "rss", "share", "shoutbox",
    "sidebar", "sociable", "sponsor", "tools"
]

let positiveScoreHints = [
    "article", "articlecontent", "instapaper_body", "blog", "body",
    "content", "entry-content-asset", "entry", "hentry", "main",
    "Normal", "page", "pagination", "permalink", "post", "story",
    "text", "[-_]copy", "\\Bcopy"
]

let negativeScoreHints = [
    "adbox", "advert", "author", "bio", "bookmark", "bottom",
    "byline", "clear", "com-", "combx", "comment", "contact",
    "copy", "credit", "crumb", "date", "deck", "excerpt",
    "featured", "foot", "footer", "footnote", "graf", "head",
    "info", "infotext", "instapaper_ignore", "jump", "linebreak",
    "link", "masthead", "media", "meta", "modal", "outbrain",
    "promo", "pr_", "related", "respond", "roundcontent", "scroll",
    "secondary", "share", "shopping", "shoutbox", "side", "sidebar",
    "sponsor", "stamp", "sub", "summary", "tags", "tools", "widget"
]
```

### B. Custom Extractor Template

```swift
struct ExampleComExtractor: Extractor {
    let domain = "example.com"

    var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1.article-title"),
            .css("h1[itemprop='headline']")
        ])
    }

    var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='author']", "content"),
            .css(".byline")
        ])
    }

    var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [.css("article.main-content")],
            transforms: [
                "img.lazy": { element in
                    // Transform lazy-loaded images
                    if let dataSrc = try? element.attr("data-src") {
                        try? element.attr("src", dataSrc)
                    }
                }
            ],
            clean: [".ad", ".social-share", ".comments"]
        )
    }

    var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='article:published_time']", "content"),
            .css("time[datetime]")
        ])
    }

    var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", "content")
        ])
    }

    var dekConfig: ExtractionConfig? { nil }
    var excerptConfig: ExtractionConfig? { nil }
    var nextPageConfig: ExtractionConfig? { nil }
    var transforms: [String: ElementTransform]? { nil }
    var clean: [String]? { nil }
}
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-13 | Claude | Initial comprehensive plan |
