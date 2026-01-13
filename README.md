# PostlightSwift

A Swift implementation of the [Postlight Parser](https://github.com/postlight/parser) - a library that extracts clean article content from any web page.

[![CI](https://github.com/iliasaz/postlight-swift/actions/workflows/ci.yml/badge.svg)](https://github.com/iliasaz/postlight-swift/actions/workflows/ci.yml)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20Linux-blue.svg)](https://swift.org)

## Features

- Extract article content, title, author, date, and more from any URL
- Custom extractors for popular sites (NYTimes, BBC, Medium, Wikipedia, etc.)
- Multiple output formats: HTML, Markdown, or plain text
- Multi-page article support with automatic pagination
- Cross-platform: macOS, iOS, tvOS, watchOS, visionOS, and Linux
- Built with Swift 6 concurrency (async/await, Sendable)

## Installation

### Swift Package Manager

Add PostlightSwift to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/iliasaz/postlight-swift.git", from: "1.0.0")
]
```

Then add it as a dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["PostlightSwift"]
)
```

## Library Usage

### Basic Usage

```swift
import PostlightSwift

let parser = Parser()

do {
    let article = try await parser.parse(url: URL(string: "https://example.com/article")!)

    print("Title: \(article.title ?? "Unknown")")
    print("Author: \(article.author ?? "Unknown")")
    print("Word Count: \(article.wordCount)")
    print("Content: \(article.content ?? "")")
} catch {
    print("Error parsing article: \(error)")
}
```

### Parse Options

```swift
import PostlightSwift

let parser = Parser()

// Configure parsing options
let options = ParserOptions(
    fetchAllPages: true,           // Fetch all pages of multi-page articles
    fallback: true,                // Fall back to generic extraction if custom fails
    contentType: .markdown,        // Output as Markdown (.html, .markdown, or .text)
    headers: [                     // Custom HTTP headers
        "User-Agent": "MyApp/1.0"
    ]
)

let article = try await parser.parse(
    url: URL(string: "https://example.com/article")!,
    options: options
)
```

### Parsing HTML Directly

```swift
import PostlightSwift

let parser = Parser()
let html = "<html><body><article>...</article></body></html>"

let article = try await parser.parse(
    html: html,
    url: URL(string: "https://example.com/article")!
)
```

### Extended Extraction

Extract custom fields using CSS selectors:

```swift
import PostlightSwift

let parser = Parser()

let options = ParserOptions(
    extend: [
        "tags": ExtractionConfig(
            selectors: [.css("meta[name='keywords']")],
            allowMultiple: true
        ),
        "category": ExtractionConfig(
            selectors: [.cssWithAttribute("meta[property='article:section']", attribute: "content")]
        )
    ]
)

let article = try await parser.parse(url: url, options: options)
// Access extended fields via article.extended["tags"], article.extended["category"]
```

### ParsedArticle Properties

| Property | Type | Description |
|----------|------|-------------|
| `title` | `String?` | Article title |
| `content` | `String?` | Main content (HTML, Markdown, or text) |
| `author` | `String?` | Author name(s) |
| `datePublished` | `Date?` | Publication date |
| `leadImageURL` | `URL?` | Lead/featured image URL |
| `dek` | `String?` | Subheadline/deck |
| `excerpt` | `String?` | Short excerpt |
| `wordCount` | `Int` | Word count |
| `direction` | `TextDirection` | Text direction (ltr/rtl) |
| `url` | `URL` | Canonical URL |
| `domain` | `String` | Domain name |
| `nextPageURL` | `URL?` | Next page URL (multi-page) |
| `totalPages` | `Int` | Total pages |
| `renderedPages` | `Int` | Pages fetched |
| `extended` | `[String: String]?` | Custom extracted fields |

## CLI Usage

### Building the CLI

```bash
# Build the CLI tool
swift build -c release

# Run directly
swift run postlight-cli https://example.com/article

# Or copy the binary
cp .build/release/postlight-cli /usr/local/bin/
```

### Basic Usage

```bash
# Parse a URL (outputs JSON)
postlight-cli https://example.com/article

# Get content as Markdown
postlight-cli https://example.com/article --format markdown

# Get content as plain text
postlight-cli https://example.com/article --format text
```

### CLI Options

```
USAGE: postlight-cli <url> [--format <format>] [--header <header> ...] [--extend <extend> ...] [--extend-list <extend-list> ...] [--verbose]

ARGUMENTS:
  <url>                   The URL to parse.

OPTIONS:
  -f, --format <format>   Output format: html, markdown, or text. (default: html)
  -H, --header <header>   HTTP header in the format 'Name=Value'. Can be specified multiple times.
  -e, --extend <extend>   Extended extraction in the format 'name=selector'. Can be specified multiple times.
  -l, --extend-list <extend-list>
                          Extended list extraction in the format 'name=selector'. Can be specified multiple times.
  -v, --verbose           Show verbose output.
  --version               Show the version.
  -h, --help              Show help information.
```

### Examples

```bash
# Parse with custom User-Agent
postlight-cli https://example.com/article -H "User-Agent=MyBot/1.0"

# Extract additional fields
postlight-cli https://example.com/article -e "tags=meta[name='keywords']|content"

# Extract list of items
postlight-cli https://example.com/article -l "images=article img|src"

# Verbose output (shows errors to stderr)
postlight-cli https://example.com/article -v
```

### Output Format

The CLI outputs JSON with the following structure:

```json
{
  "title": "Article Title",
  "content": "<p>Article content...</p>",
  "author": "John Doe",
  "date_published": "2024-01-15T10:30:00Z",
  "lead_image_url": "https://example.com/image.jpg",
  "dek": "Article subtitle",
  "excerpt": "A brief excerpt...",
  "word_count": 1250,
  "direction": "ltr",
  "url": "https://example.com/article",
  "domain": "example.com",
  "next_page_url": null,
  "total_pages": 1,
  "rendered_pages": 1
}
```

Error output:

```json
{
  "error": true,
  "message": "Error description"
}
```

## Supported Sites

PostlightSwift includes 40+ custom extractors for optimal results on these sites:

- **News**: NYTimes, BBC, The Guardian, Washington Post, CNN, Reuters, NPR, Politico, Bloomberg, CNBC, The Atlantic, Slate, Vox, NBC News, ABC News, The New Yorker, HuffPost
- **Tech**: TechCrunch, Wired, Ars Technica, The Verge, Engadget, CNET, Gizmodo, Mashable, MacRumors, ZDNet, Lifehacker
- **Entertainment**: Buzzfeed, Rolling Stone, Pitchfork, TMZ, People
- **Business**: Fortune, Fast Company, Forbes, Business Insider
- **Sports**: ESPN, Sports Illustrated, Bleacher Report
- **Platforms**: Medium, Substack, Hacker News, Reddit, YouTube, GitHub
- **Reference**: Wikipedia, Quartz

For other sites, the generic extractor uses content scoring algorithms similar to Mozilla's Readability.

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+
- Linux (Ubuntu 20.04+, Amazon Linux 2, etc.)

## Development

```bash
# Clone the repository
git clone https://github.com/iliasaz/postlight-swift.git
cd postlight-swift

# Build
swift build

# Run tests
swift test

# Run the CLI
swift run postlight-cli https://example.com/article
```

## Acknowledgments

This is a Swift port of the original [Postlight Parser](https://github.com/postlight/parser) JavaScript library. The extraction algorithms and approach are based on that project.

## License

MIT License - see [LICENSE](LICENSE) for details.
