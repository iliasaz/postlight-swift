import Foundation

/// Constants used by the content extraction scoring algorithm.
///
/// These patterns are ported from the original Postlight Parser JavaScript implementation.
public enum ScoringConstants {
    // MARK: - Unlikely Candidates

    /// Patterns that indicate an element is unlikely to be article content.
    public static let unlikelyCandidatesBlacklist = [
        "ad-break",
        "adbox",
        "advert",
        "addthis",
        "agegate",
        "aux",
        "blogger-labels",
        "combx",
        "comment",
        "conversation",
        "disqus",
        "entry-unrelated",
        "extra",
        "foot",
        "form",
        "header",
        "hidden",
        "loader",
        "login",
        "menu",
        "meta",
        "nav",
        "pager",
        "pagination",
        "predicta",
        "presence_control_external",
        "popup",
        "printfriendly",
        "related",
        "remove",
        "remark",
        "rss",
        "share",
        "shoutbox",
        "sidebar",
        "sociable",
        "sponsor",
        "tools",
    ]

    /// Patterns that indicate an element is likely to be article content.
    public static let unlikelyCandidatesWhitelist = [
        "and",
        "article",
        "body",
        "blogindex",
        "column",
        "content",
        "entry-content-asset",
        "format",
        "hfeed",
        "hentry",
        "hatom",
        "main",
        "page",
        "posts",
        "shadow",
    ]

    // MARK: - Scoring Hints

    /// Patterns that indicate positive scoring for content.
    public static let positiveScoreHints = [
        "article",
        "articlecontent",
        "instapaper_body",
        "blog",
        "body",
        "content",
        "entry-content-asset",
        "entry",
        "hentry",
        "main",
        "Normal",
        "page",
        "pagination",
        "permalink",
        "post",
        "story",
        "text",
        "[-_]copy",
        "\\Bcopy",
    ]

    /// Patterns that indicate negative scoring for content.
    public static let negativeScoreHints = [
        "adbox",
        "advert",
        "author",
        "bio",
        "bookmark",
        "bottom",
        "byline",
        "clear",
        "com-",
        "combx",
        "comment",
        "comment\\B",
        "contact",
        "copy",
        "credit",
        "crumb",
        "date",
        "deck",
        "excerpt",
        "featured",
        "foot",
        "footer",
        "footnote",
        "graf",
        "head",
        "info",
        "infotext",
        "instapaper_ignore",
        "jump",
        "linebreak",
        "link",
        "masthead",
        "media",
        "meta",
        "modal",
        "outbrain",
        "promo",
        "pr_",
        "related",
        "respond",
        "roundcontent",
        "scroll",
        "secondary",
        "share",
        "shopping",
        "shoutbox",
        "side",
        "sidebar",
        "sponsor",
        "stamp",
        "sub",
        "summary",
        "tags",
        "tools",
        "widget",
    ]

    /// Patterns that indicate photo content (bonus scoring).
    public static let photoHints = ["figure", "photo", "image", "caption"]

    // MARK: - Block Level Tags

    /// Tags that indicate block-level content (don't convert divs containing these to paragraphs).
    public static let divToBlockTags = "a, blockquote, dl, div, img, p, pre, table"

    /// Tags that should not be considered as top candidates.
    public static let nonTopCandidateTags: Set<String> = [
        "br", "b", "i", "label", "hr", "area", "base", "basefont",
        "input", "img", "link", "meta"
    ]

    /// Block level tags in HTML5.
    public static let blockLevelTags: Set<String> = [
        "article", "aside", "blockquote", "body", "br", "button",
        "canvas", "caption", "col", "colgroup", "dd", "div", "dl",
        "dt", "embed", "fieldset", "figcaption", "figure", "footer",
        "form", "h1", "h2", "h3", "h4", "h5", "h6", "header",
        "hgroup", "hr", "li", "map", "object", "ol", "output", "p",
        "pre", "progress", "section", "table", "tbody", "textarea",
        "tfoot", "th", "thead", "tr", "ul", "video"
    ]

    // MARK: - hNews Content Selectors

    /// Selectors that indicate hNews or blog post content (high confidence).
    public static let hNewsContentSelectors: [(String, String)] = [
        (".hentry", ".entry-content"),
        ("entry", ".entry-content"),
        (".entry", ".entry_content"),
        (".post", ".postbody"),
        (".post", ".post_body"),
        (".post", ".post-body"),
    ]

    // MARK: - Content Thresholds

    /// Minimum content length to consider extraction successful.
    public static let minimumContentLength = 200

    // MARK: - Compiled Patterns

    /// Compiled regex for candidates blacklist.
    public static let candidatesBlacklistPattern = RegexPattern(
        pattern: unlikelyCandidatesBlacklist.joined(separator: "|"),
        options: .caseInsensitive
    )

    /// Compiled regex for candidates whitelist.
    public static let candidatesWhitelistPattern = RegexPattern(
        pattern: unlikelyCandidatesWhitelist.joined(separator: "|"),
        options: .caseInsensitive
    )

    /// Compiled regex for positive score hints.
    public static let positiveScorePattern = RegexPattern(
        pattern: positiveScoreHints.joined(separator: "|"),
        options: .caseInsensitive
    )

    /// Compiled regex for negative score hints.
    public static let negativeScorePattern = RegexPattern(
        pattern: negativeScoreHints.joined(separator: "|"),
        options: .caseInsensitive
    )

    /// Compiled regex for photo hints.
    public static let photoHintsPattern = RegexPattern(
        pattern: photoHints.joined(separator: "|"),
        options: .caseInsensitive
    )

    /// Compiled regex for readability asset class.
    public static let readabilityAssetPattern = RegexPattern(
        pattern: "entry-content-asset",
        options: .caseInsensitive
    )
}

// MARK: - Regex Helper

/// A simple regex pattern wrapper for efficient matching.
public struct RegexPattern: Sendable {
    private let regex: NSRegularExpression?

    public init(pattern: String, options: NSRegularExpression.Options = []) {
        self.regex = try? NSRegularExpression(pattern: pattern, options: options)
    }

    /// Returns true if the pattern matches anywhere in the string.
    public func hasMatch(in string: String) -> Bool {
        guard let regex = regex else { return false }
        let range = NSRange(string.startIndex..., in: string)
        return regex.firstMatch(in: string, options: [], range: range) != nil
    }

    /// Returns all matches in the string.
    public func matches(in string: String) -> [String] {
        guard let regex = regex else { return [] }
        let range = NSRange(string.startIndex..., in: string)
        return regex.matches(in: string, options: [], range: range).compactMap { result in
            guard let range = Range(result.range, in: string) else { return nil }
            return String(string[range])
        }
    }
}
