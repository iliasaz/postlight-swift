import Foundation

/// Custom extractor for The Guardian (www.theguardian.com).
public struct GuardianExtractor: Extractor, Sendable {
    public let domain = "www.theguardian.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1[data-gu-name='headline']"),
            .css("h1.content__headline"),
            .css("h1.dcr-y70mar"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[data-link-name='byline']"),
            .css(".byline"),
            .css("a[rel='author']"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
            .css(".content__dateline-wpd"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css("[data-gu-name='body']"),
                .css(".content__article-body"),
                .css("#maincontent"),
                .css("article"),
            ],
            clean: [
                ".ad-slot",
                ".submeta",
                ".content__meta-container",
                ".block-share",
                ".inline-expand-image",
                "[data-component='rich-link']",
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
            .css("[data-gu-name='standfirst']"),
            .css(".content__standfirst"),
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
