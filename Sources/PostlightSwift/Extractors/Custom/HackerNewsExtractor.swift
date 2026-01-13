import Foundation

/// Custom extractor for Hacker News (news.ycombinator.com).
public struct HackerNewsExtractor: Extractor, Sendable {
    public let domain = "news.ycombinator.com"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".titleline a"),
            .css(".storylink"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css(".hnuser"),
        ])
    }

    public var datePublishedConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute(".age", attribute: "title"),
        ])
    }

    public var contentConfig: ExtractionConfig? {
        // HN doesn't have article content in the traditional sense
        // This would extract comments
        ExtractionConfig(
            selectors: [
                .css(".comment-tree"),
                .css(".commtext"),
            ],
            clean: [
                ".noshow",
                ".votearrow",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        nil
    }

    public var dekConfig: ExtractionConfig? {
        nil
    }

    public var excerptConfig: ExtractionConfig? {
        nil
    }

    public var nextPageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute(".morelink", attribute: "href"),
        ])
    }
}
