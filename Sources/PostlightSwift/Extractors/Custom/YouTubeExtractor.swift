import Foundation

/// Custom extractor for YouTube (www.youtube.com).
public struct YouTubeExtractor: Extractor, Sendable {
    public let domain = "www.youtube.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1.title yt-formatted-string"),
            .css("h1.ytd-video-primary-info-renderer"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
            .cssWithAttribute("meta[name='title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("#channel-name a"),
            .css("ytd-channel-name a"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[itemprop='datePublished']", attribute: "content"),
            .cssWithAttribute("meta[itemprop='uploadDate']", attribute: "content"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css("#description-text"),
                .css("ytd-text-inline-expander #content"),
                .css("#description"),
            ],
            clean: []
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute("link[itemprop='thumbnailUrl']", attribute: "href"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
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
