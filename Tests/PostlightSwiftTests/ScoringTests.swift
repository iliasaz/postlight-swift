import XCTest
@testable import PostlightSwift

final class ScoringTests: XCTestCase {
    // MARK: - Regex Pattern Tests

    func testCandidatesBlacklistPattern() {
        let pattern = ScoringConstants.candidatesBlacklistPattern

        XCTAssertTrue(pattern.hasMatch(in: "sidebar"))
        XCTAssertTrue(pattern.hasMatch(in: "nav-menu"))
        XCTAssertTrue(pattern.hasMatch(in: "advertisement"))
        XCTAssertTrue(pattern.hasMatch(in: "comment-section"))
        XCTAssertTrue(pattern.hasMatch(in: "footer-links"))

        XCTAssertFalse(pattern.hasMatch(in: "article-content"))
        XCTAssertFalse(pattern.hasMatch(in: "main-text"))
    }

    func testCandidatesWhitelistPattern() {
        let pattern = ScoringConstants.candidatesWhitelistPattern

        XCTAssertTrue(pattern.hasMatch(in: "article"))
        XCTAssertTrue(pattern.hasMatch(in: "content"))
        XCTAssertTrue(pattern.hasMatch(in: "entry-content"))
        XCTAssertTrue(pattern.hasMatch(in: "main"))
        XCTAssertTrue(pattern.hasMatch(in: "hentry"))

        XCTAssertFalse(pattern.hasMatch(in: "sidebar"))
        XCTAssertFalse(pattern.hasMatch(in: "nav"))
    }

    func testPositiveScorePattern() {
        let pattern = ScoringConstants.positiveScorePattern

        XCTAssertTrue(pattern.hasMatch(in: "article"))
        XCTAssertTrue(pattern.hasMatch(in: "blog-post"))
        XCTAssertTrue(pattern.hasMatch(in: "entry-content"))
        XCTAssertTrue(pattern.hasMatch(in: "story"))
        XCTAssertTrue(pattern.hasMatch(in: "post-body"))
    }

    func testNegativeScorePattern() {
        let pattern = ScoringConstants.negativeScorePattern

        XCTAssertTrue(pattern.hasMatch(in: "sidebar"))
        XCTAssertTrue(pattern.hasMatch(in: "footer"))
        XCTAssertTrue(pattern.hasMatch(in: "comment"))
        XCTAssertTrue(pattern.hasMatch(in: "advertisement"))
        XCTAssertTrue(pattern.hasMatch(in: "share-buttons"))
    }

    func testPhotoHintsPattern() {
        let pattern = ScoringConstants.photoHintsPattern

        XCTAssertTrue(pattern.hasMatch(in: "figure"))
        XCTAssertTrue(pattern.hasMatch(in: "photo-gallery"))
        XCTAssertTrue(pattern.hasMatch(in: "image-container"))
        XCTAssertTrue(pattern.hasMatch(in: "caption"))
    }

    // MARK: - Constants Tests

    func testNonTopCandidateTags() {
        XCTAssertTrue(ScoringConstants.nonTopCandidateTags.contains("br"))
        XCTAssertTrue(ScoringConstants.nonTopCandidateTags.contains("img"))
        XCTAssertTrue(ScoringConstants.nonTopCandidateTags.contains("meta"))
        XCTAssertTrue(ScoringConstants.nonTopCandidateTags.contains("link"))

        XCTAssertFalse(ScoringConstants.nonTopCandidateTags.contains("div"))
        XCTAssertFalse(ScoringConstants.nonTopCandidateTags.contains("p"))
        XCTAssertFalse(ScoringConstants.nonTopCandidateTags.contains("article"))
    }

    func testBlockLevelTags() {
        XCTAssertTrue(ScoringConstants.blockLevelTags.contains("div"))
        XCTAssertTrue(ScoringConstants.blockLevelTags.contains("p"))
        XCTAssertTrue(ScoringConstants.blockLevelTags.contains("article"))
        XCTAssertTrue(ScoringConstants.blockLevelTags.contains("section"))
        XCTAssertTrue(ScoringConstants.blockLevelTags.contains("header"))
        XCTAssertTrue(ScoringConstants.blockLevelTags.contains("footer"))

        XCTAssertFalse(ScoringConstants.blockLevelTags.contains("span"))
        XCTAssertFalse(ScoringConstants.blockLevelTags.contains("a"))
        XCTAssertFalse(ScoringConstants.blockLevelTags.contains("strong"))
    }

    func testHNewsContentSelectors() {
        XCTAssertFalse(ScoringConstants.hNewsContentSelectors.isEmpty)

        // Check that we have the expected selectors
        let selectors = ScoringConstants.hNewsContentSelectors
        XCTAssertTrue(selectors.contains { $0.0 == ".hentry" && $0.1 == ".entry-content" })
        XCTAssertTrue(selectors.contains { $0.0 == ".post" && $0.1 == ".post-body" })
    }

    // MARK: - Minimum Content Length

    func testMinimumContentLength() {
        XCTAssertEqual(ScoringConstants.minimumContentLength, 200)
    }
}
