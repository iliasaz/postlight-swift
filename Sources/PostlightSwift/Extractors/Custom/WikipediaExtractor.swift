import Foundation

/// Custom extractor for Wikipedia (en.wikipedia.org and other language editions).
public struct WikipediaExtractor: Extractor, Sendable {
    public let domain = "en.wikipedia.org"

    public init() {}

    public var titleConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .css("#firstHeading"),
            .css("h1.firstHeading"),
            .css("h1#firstHeading"),
        ])
    }

    public var authorConfig: ExtractionConfig? {
        // Wikipedia articles don't have traditional authors
        nil
    }

    public var datePublishedConfig: ExtractionConfig? {
        // Wikipedia modification dates are complex
        nil
    }

    public var contentConfig: ExtractionConfig? {
        ExtractionConfig(
            selectors: [
                .css("#mw-content-text .mw-parser-output"),
                .css("#bodyContent"),
                .css(".mw-body-content"),
            ],
            clean: [
                ".mw-editsection",
                ".navbox",
                ".vertical-navbox",
                ".sistersitebox",
                ".noprint",
                ".mw-empty-elt",
                "#toc",
                ".toc",
                ".thumb",
                ".infobox",
                ".sidebar",
                ".reflist",
                ".reference",
                ".mw-references-wrap",
                ".mw-headline-anchor",
                "[role='navigation']",
                ".catlinks",
                "#catlinks",
                ".hatnote",
                ".shortdescription",
            ]
        )
    }

    public var leadImageConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[property='og:image']", attribute: "content"),
            .cssWithAttribute(".infobox img", attribute: "src"),
            .cssWithAttribute(".thumb img", attribute: "src"),
        ])
    }

    public var dekConfig: ExtractionConfig? {
        // Wikipedia uses the first paragraph as a summary
        ExtractionConfig(selectors: [
            .css("#mw-content-text .mw-parser-output > p:first-of-type"),
        ])
    }

    public var excerptConfig: ExtractionConfig? {
        ExtractionConfig(selectors: [
            .cssWithAttribute("meta[name='description']", attribute: "content"),
            .css("#mw-content-text .mw-parser-output > p:first-of-type"),
        ])
    }

    public var nextPageConfig: ExtractionConfig? {
        nil
    }
}
