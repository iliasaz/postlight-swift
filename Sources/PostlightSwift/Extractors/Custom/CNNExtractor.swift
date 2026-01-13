import Foundation

/// Custom extractor for CNN (www.cnn.com).
public struct CNNExtractor: Extractor, Sendable {
    public let domain = "www.cnn.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1.headline__text"),
            .css("h1.pg-headline"),
            .css("h1[data-editable='headlineText']"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".byline__name"),
            .css(".metadata__byline__author"),
            .css("[data-type='byline-area']"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
            .css(".timestamp"),
            .css(".update-time"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css("article.article__content"),
                .css(".article__content-container"),
                .css(".zn-body__paragraph"),
                .css(".l-container"),
            ],
            clean: [
                ".ad",
                ".el__embedded",
                ".el__leafmedia",
                ".zn-body__footer",
                ".cn-carousel-medium-strip",
                "[data-analytics='outbrain-paid_content_1']",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute(".image__picture img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".headline__dek"),
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
