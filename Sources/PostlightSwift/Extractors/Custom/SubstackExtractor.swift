import Foundation

/// Custom extractor for Substack newsletters.
///
/// Works with any subdomain.substack.com site.
public struct SubstackExtractor: Extractor, Sendable {
    public let domain = "substack.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1.post-title"),
            .css("h1[data-testid='post-title']"),
            .css("h1.headline"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".author-name"),
            .css(".byline-content a"),
            .css("[data-testid='byline'] a"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
            .css(".post-date"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css(".body.markup"),
                .css(".post-content"),
                .css("[data-testid='post-body']"),
                .css(".available-content"),
            ],
            clean: [
                ".subscription-widget",
                ".paywall",
                ".share-dialog",
                "[data-testid='paywall']",
                ".post-footer",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute(".post-hero img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".subtitle"),
            .css(".post-subtitle"),
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
