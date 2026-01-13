import Foundation

/// Custom extractor for Medium (medium.com and custom domains).
///
/// Handles Medium's specific article structure.
public struct MediumExtractor: Extractor, Sendable {
    public let domain = "medium.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
            .cssWithAttribute("meta[name='title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[data-testid='authorName']"),
            .css("a[rel='author']"),
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
                .css("article"),
                .css("section[data-field='body']"),
                .css(".postArticle-content"),
            ],
            clean: [
                ".progressiveMedia-thumbnail",
                ".js-postMetaLockup",
                ".postActions",
                ".followingButton",
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
            .css("h2"),
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
