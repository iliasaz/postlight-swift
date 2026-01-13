import Foundation

/// Custom extractor for The Atlantic (www.theatlantic.com).
public struct TheAtlanticExtractor: Extractor, Sendable {
    public let domain = "www.theatlantic.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1"),
            .css(".c-article-header__hed"),
            .css(".article-header__hed"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='author']", attribute: "content"),
            .css(".c-byline__author"),
            .css(".byline a"),
            .css("[itemprop='author'] [itemprop='name']"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("time[itemprop='datePublished']", attribute: "datetime"),
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css("article"),
                .css(".article-body"),
                .css(".c-article-body"),
            ],
            clean: [
                ".ad",
                ".callout",
                ".newsletter-module",
                ".article-related",
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
            .cssWithAttribute("meta[name='description']", attribute: "content"),
            .css(".c-article-header__dek"),
            .css(".article-header__dek"),
        ])
    }

    public var excerptConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='description']", attribute: "content"),
        ])
    }

    public var nextPageConfig: ExtractionConfig? { nil }
}
