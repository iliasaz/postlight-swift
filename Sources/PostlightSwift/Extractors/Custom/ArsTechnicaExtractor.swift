import Foundation

/// Custom extractor for Ars Technica (arstechnica.com).
public struct ArsTechnicaExtractor: Extractor, Sendable {
    public let domain = "arstechnica.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1[itemprop='headline']"),
            .css("h1.heading"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[itemprop='author'] [itemprop='name']"),
            .css("a[rel='author']"),
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
                .css("[itemprop='articleBody']"),
                .css(".article-content"),
                .css(".post-content"),
            ],
            clean: [
                ".ad",
                ".gallery-overlay",
                ".sidebar",
                ".related-stories",
                ".post-meta",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute(".header-image img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("p[itemprop='description']"),
            .css(".intro"),
            .cssWithAttribute("meta[property='og:description']", attribute: "content"),
        ])
    }

    public var excerptConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='description']", attribute: "content"),
        ])
    }

    public var nextPageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("link[rel='next']", attribute: "href"),
            .cssWithAttribute(".next a", attribute: "href"),
        ])
    }
}
