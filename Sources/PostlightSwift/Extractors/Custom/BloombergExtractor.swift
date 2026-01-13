import Foundation

/// Custom extractor for Bloomberg (www.bloomberg.com).
public struct BloombergExtractor: Extractor, Sendable {
    public let domain = "www.bloomberg.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".lede-headline"),
            .css("h1.article-title"),
            .css("h1[class^='headline']"),
            .css("h1.lede-text-only__hed"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='parsely-author']", attribute: "content"),
            .css(".byline-details__link"),
            .css(".bydek"),
            .css(".author"),
            .css("p[class*='author']"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("time.published-at", attribute: "datetime"),
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
            .cssWithAttribute("meta[name='date']", attribute: "content"),
            .cssWithAttribute("meta[name='parsely-pub-date']", attribute: "content"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css(".article-body__content"),
                .css(".body-content"),
                .css("section.copy-block"),
                .css(".body-copy"),
                .css("article"),
            ],
            clean: [
                ".inline-newsletter",
                ".page-ad",
                ".ad",
                ".newsletter-tout",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".lede-dek"),
            .cssWithAttribute("meta[property='og:description']", attribute: "content"),
        ])
    }

    public var excerptConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='description']", attribute: "content"),
        ])
    }

    public var nextPageConfig: ExtractionConfig? { nil }
}
