import Foundation

/// Custom extractor for BBC News (www.bbc.com).
public struct BBCExtractor: Extractor, Sendable {
    public let domain = "www.bbc.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1#main-heading"),
            .css("h1.story-headline"),
            .css("h1.story-body__h1"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".byline__name"),
            .css(".contributor-name"),
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
                .css("article[role='main']"),
                .css(".story-body"),
                .css("#story-body"),
                .css("[data-component='text-block']"),
            ],
            clean: [
                ".share-tools",
                ".story-more",
                ".related-links",
                ".tags-container",
                ".media-caption",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute("figure img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".story-body__introduction"),
            .css("p.story-summary"),
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
