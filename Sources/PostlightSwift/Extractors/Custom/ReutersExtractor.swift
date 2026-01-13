import Foundation

/// Custom extractor for Reuters (www.reuters.com).
public struct ReutersExtractor: Extractor, Sendable {
    public let domain = "www.reuters.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("h1[data-testid='Heading']"),
            .css("h1.article-header__title"),
            .css("h1.ArticleHeader_headline"),
            .cssWithAttribute("meta[property='og:title']", attribute: "content"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[data-testid='author-name']"),
            .css(".author-name"),
            .css(".BylineBar_byline a"),
            .cssWithAttribute("meta[name='author']", attribute: "content"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='article:published_time']", attribute: "content"),
            .cssWithAttribute("time[datetime]", attribute: "datetime"),
            .css("[data-testid='published-date']"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css("[data-testid='article-body']"),
                .css(".article-body__content"),
                .css(".StandardArticleBody_body"),
            ],
            clean: [
                ".ad-container",
                ".related-coverage",
                ".trust-badge",
                "[data-testid='ad']",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute("[data-testid='primary-image'] img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("[data-testid='article-summary']"),
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
