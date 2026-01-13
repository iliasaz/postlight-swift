import Foundation

/// Custom extractor for The New York Times (www.nytimes.com).
///
/// This extractor handles NYT's specific HTML structure for optimal
/// content extraction.
public struct NYTimesExtractor: Extractor, Sendable {
    public let domain = "www.nytimes.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1[data-testid='headline']"),
            .css("h1.headline"),
            .css("h1[itemprop='headline']"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[itemprop='author'] [itemprop='name']"),
            .css(".byline-author"),
            .css("[data-testid='byline']"),
            .cssWithAttribute("meta[name='byl']", attribute: "content"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
            .css("time.dateline"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css("section[name='articleBody']"),
                .css("article[itemprop='articleBody']"),
                .css(".article-body"),
                .css(".story-body"),
            ],
            clean: [
                ".ad",
                ".advertisement",
                ".newsletter-signup",
                ".related-links",
                "[data-testid='inline-message']",
                ".story-ad",
                ".hidden",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute("figure img", attribute: "src"),
            .cssWithAttribute("picture img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("p.summary"),
            .css("[data-testid='standfirst']"),
            .cssWithAttribute("meta[property='og:description']", attribute: "content"),
        ])
    }

    public var excerptConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='description']", attribute: "content"),
            .cssWithAttribute("meta[property='og:description']", attribute: "content"),
        ])
    }

    public var nextPageConfig: ExtractionConfig? {
        nil // NYT doesn't typically paginate articles
    }
}
