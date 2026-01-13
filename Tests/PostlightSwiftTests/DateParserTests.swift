import XCTest
@testable import PostlightSwift

final class DateParserTests: XCTestCase {
    // MARK: - ISO 8601 Tests

    func testParseISO8601WithTimezone() {
        let date = DateParser.parse("2024-01-15T10:30:00Z")
        XCTAssertNotNil(date)
    }

    func testParseISO8601WithOffset() {
        let date = DateParser.parse("2024-01-15T10:30:00+05:00")
        XCTAssertNotNil(date)
    }

    func testParseISO8601WithFractionalSeconds() {
        let date = DateParser.parse("2024-01-15T10:30:00.123Z")
        XCTAssertNotNil(date)
    }

    func testParseISO8601DateOnly() {
        let date = DateParser.parse("2024-01-15")
        XCTAssertNotNil(date)
    }

    // MARK: - Relative Time Tests

    func testParseRelativeNow() {
        let date = DateParser.parse("just now")
        XCTAssertNotNil(date)

        // Should be very close to now
        if let date = date {
            let diff = abs(date.timeIntervalSinceNow)
            XCTAssertLessThan(diff, 5)
        }
    }

    func testParseRelativeHoursAgo() {
        let date = DateParser.parse("2 hours ago")
        XCTAssertNotNil(date)

        if let date = date {
            let diff = abs(date.timeIntervalSinceNow + 2 * 3600)
            XCTAssertLessThan(diff, 60)
        }
    }

    func testParseRelativeDaysAgo() {
        let date = DateParser.parse("3 days ago")
        XCTAssertNotNil(date)

        if let date = date {
            let diff = abs(date.timeIntervalSinceNow + 3 * 86400)
            XCTAssertLessThan(diff, 3600)
        }
    }

    func testParseRelativeYesterday() {
        let date = DateParser.parse("yesterday")
        XCTAssertNotNil(date)
    }

    // MARK: - Common Format Tests

    func testParseUSFormat() {
        let date = DateParser.parse("01/15/2024")
        XCTAssertNotNil(date)
    }

    func testParseLongFormat() {
        let date = DateParser.parse("January 15, 2024")
        XCTAssertNotNil(date)
    }

    func testParseShortMonthFormat() {
        let date = DateParser.parse("Jan 15, 2024")
        XCTAssertNotNil(date)
    }

    func testParseEuropeanFormat() {
        let date = DateParser.parse("15/01/2024")
        XCTAssertNotNil(date)
    }

    // MARK: - Edge Cases

    func testParseEmptyString() {
        let date = DateParser.parse("")
        XCTAssertNil(date)
    }

    func testParseWhitespaceOnly() {
        let date = DateParser.parse("   ")
        XCTAssertNil(date)
    }

    func testParseInvalidString() {
        let date = DateParser.parse("not a date")
        XCTAssertNil(date)
    }

    // MARK: - Format Output Tests

    func testFormatISO8601() {
        let date = Date(timeIntervalSince1970: 1705315800) // 2024-01-15T10:30:00Z
        let formatted = DateParser.formatISO8601(date)
        XCTAssertTrue(formatted.contains("2024-01-15"))
    }
}
