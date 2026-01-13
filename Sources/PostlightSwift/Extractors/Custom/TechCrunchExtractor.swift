import Foundation

/// Custom extractor for TechCrunch (techcrunch.com).
public struct TechCrunchExtractor: Extractor, Sendable {
    public let domain = "techcrunch.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1.article__title"),
            .css("h1.post-title"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".article__byline a"),
            .css(".byline a"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css(".article-content"),
                .css(".article__content"),
                .css(".post-content"),
            ],
            clean: [
                ".embed-tc",
                ".newsletter-signup",
                ".related-posts",
                "[data-ad]",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute(".article__featured-image img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".article__deck"),
            .cssWithAttribute("meta[property='og:description']", attribute: "content"),
        ])
    }

    public var excerptConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='description']", attribute: "content"),
        ])
    }

    public var nextPageConfig: ExtractionConfig? {
        nil
    }
}
