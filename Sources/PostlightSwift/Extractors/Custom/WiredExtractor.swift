import Foundation

/// Custom extractor for Wired (www.wired.com).
public struct WiredExtractor: Extractor, Sendable {
    public let domain = "www.wired.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1[data-testid='ContentHeaderHed']"),
            .css("h1.content-header__row--title"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[data-testid='BylineNameLink']"),
            .css(".byline__name a"),
            .css("[itemprop='author'] [itemprop='name']"),
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
                .css("[data-testid='BodyWrapper']"),
                .css(".body__inner-container"),
                .css("article .content"),
            ],
            clean: [
                ".ad",
                ".newsletter-subscribe-form",
                ".related-links",
                "[data-testid='AdWrapper']",
                ".social-icons",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute("[data-testid='ContentHeaderLeadAsset'] img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[data-testid='ContentHeaderDek']"),
            .css(".content-header__dek"),
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
