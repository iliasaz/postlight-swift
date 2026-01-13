import Foundation

/// Custom extractor for Politico (www.politico.com).
public struct PoliticoExtractor: Extractor, Sendable {
    public let domain = "www.politico.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
            .css("h1"),
            .css(".headline"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("div[itemprop='author'] meta[itemprop='name']"),
            .css(".story-meta__authors .vcard"),
            .css(".story-main-content .byline .vcard"),
            .css(".byline a"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("time[itemprop='datePublished']", attribute: "datetime"),
            .cssWithAttribute(".story-meta__details time[datetime]", attribute: "datetime"),
            .cssWithAttribute(".timestamp time[datetime]", attribute: "datetime"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css(".story-text"),
                .css(".story-main-content"),
                .css(".story-core"),
                .css("article"),
            ],
            clean: [
                "figcaption",
                ".story-meta",
                ".ad",
                ".module-tout",
                ".story-interrupt",
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
            .cssWithAttribute("meta[property='og:description']", attribute: "content"),
            .css(".dek"),
        ])
    }

    public var excerptConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='description']", attribute: "content"),
        ])
    }

    public var nextPageConfig: ExtractionConfig? { nil }
}
