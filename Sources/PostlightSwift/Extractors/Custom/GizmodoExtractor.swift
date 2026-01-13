import Foundation

/// Custom extractor for Gizmodo (gizmodo.com).
public struct GizmodoExtractor: Extractor, Sendable {
    public let domain = "gizmodo.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1.sc-1efpnfq-0"),
            .css("h1"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("a[data-ga*='Author']"),
            .css(".author-name a"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css(".js_post-content"),
                .css("article .entry-content"),
                .css("article"),
            ],
            clean: [
                ".ad",
                ".related-stories",
                ".newsletter-signup",
                ".commerce-inset",
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
            .css(".excerpt"),
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
