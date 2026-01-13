import Foundation

/// Custom extractor for The Washington Post (www.washingtonpost.com).
public struct WashingtonPostExtractor: Extractor, Sendable {
    public let domain = "www.washingtonpost.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1[data-qa='headline']"),
            .css("h1.headline"),
            .css("#article-topper h1"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[data-qa='author-name']"),
            .css(".author-name"),
            .css(".byline a"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
            .css(".display-date"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css("[data-qa='article-body']"),
                .css(".article-body"),
                .css("article[itemprop='articleBody']"),
            ],
            clean: [
                ".ad",
                ".newsletter-inline",
                ".interstitial-link",
                ".related-links",
                "[data-qa='subscribe-promo']",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute("[data-qa='lede-art'] img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[data-qa='subheadline']"),
            .css(".dek"),
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
