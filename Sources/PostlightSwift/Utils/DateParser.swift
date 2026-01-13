import Foundation

/// Utility for parsing dates from various formats commonly found in web articles.
///
/// This implementation supports:
/// - ISO 8601 formats
/// - Common date formats used by news sites
/// - Relative time expressions ("2 hours ago", "yesterday")
public enum DateParser {
    // MARK: - Main Parsing Function

    /// Parses a date string into a Date object.
    ///
    /// Attempts multiple parsing strategies in order of specificity.
    /// - Parameter string: The date string to parse.
    /// - Returns: A Date if parsing succeeds, nil otherwise.
    public static func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try ISO 8601 first (most common for structured data)
        if let date = parseISO8601(trimmed) {
            return date
        }

        // Try relative time expressions
        if let date = parseRelativeTime(trimmed) {
            return date
        }

        // Try common date formats
        if let date = parseCommonFormats(trimmed) {
            return date
        }

        return nil
    }

    // MARK: - ISO 8601 Parsing

    private static func parseISO8601(_ string: String) -> Date? {
        // Try with fractional seconds
        let fullFormatter = ISO8601DateFormatter()
        fullFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fullFormatter.date(from: string) {
            return date
        }

        // Try standard ISO 8601
        let standardFormatter = ISO8601DateFormatter()
        standardFormatter.formatOptions = [.withInternetDateTime]
        if let date = standardFormatter.date(from: string) {
            return date
        }

        // Try date only
        let dateOnlyFormatter = ISO8601DateFormatter()
        dateOnlyFormatter.formatOptions = [.withFullDate]
        if let date = dateOnlyFormatter.date(from: string) {
            return date
        }

        // Try with timezone offset variations
        let patterns = [
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for pattern in patterns {
            formatter.dateFormat = pattern
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    // MARK: - Relative Time Parsing

    private static func parseRelativeTime(_ string: String) -> Date? {
        let lowercased = string.lowercased()

        // Check for common relative expressions
        if lowercased == "now" || lowercased == "just now" {
            return Date()
        }

        if lowercased == "today" {
            return Calendar.current.startOfDay(for: Date())
        }

        if lowercased == "yesterday" {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())
        }

        // Pattern: "X minutes/hours/days ago"
        let agoPattern = /(\d+)\s*(second|minute|hour|day|week|month|year)s?\s*ago/
        if let match = lowercased.firstMatch(of: agoPattern) {
            let value = Int(match.1) ?? 0
            let unit = String(match.2)

            let component: Calendar.Component
            switch unit {
            case "second": component = .second
            case "minute": component = .minute
            case "hour": component = .hour
            case "day": component = .day
            case "week": component = .weekOfYear
            case "month": component = .month
            case "year": component = .year
            default: return nil
            }

            return Calendar.current.date(byAdding: component, value: -value, to: Date())
        }

        // Pattern: "in X minutes/hours/days" (future)
        let futurePattern = /in\s+(\d+)\s*(second|minute|hour|day|week|month|year)s?/
        if let match = lowercased.firstMatch(of: futurePattern) {
            let value = Int(match.1) ?? 0
            let unit = String(match.2)

            let component: Calendar.Component
            switch unit {
            case "second": component = .second
            case "minute": component = .minute
            case "hour": component = .hour
            case "day": component = .day
            case "week": component = .weekOfYear
            case "month": component = .month
            case "year": component = .year
            default: return nil
            }

            return Calendar.current.date(byAdding: component, value: value, to: Date())
        }

        return nil
    }

    // MARK: - Common Format Parsing

    private static let commonFormats = [
        // US formats
        "MM/dd/yyyy",
        "MM-dd-yyyy",
        "MM/dd/yy",
        "M/d/yyyy",
        "M/d/yy",

        // European formats
        "dd/MM/yyyy",
        "dd-MM-yyyy",
        "dd.MM.yyyy",
        "d/M/yyyy",

        // Long formats
        "MMMM d, yyyy",
        "MMMM d yyyy",
        "MMM d, yyyy",
        "MMM d yyyy",
        "d MMMM yyyy",
        "d MMM yyyy",
        "MMMM dd, yyyy",
        "MMM dd, yyyy",

        // With time
        "MMMM d, yyyy 'at' h:mm a",
        "MMMM d, yyyy h:mm a",
        "MMM d, yyyy 'at' h:mm a",
        "MM/dd/yyyy h:mm a",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd HH:mm",
        "dd/MM/yyyy HH:mm:ss",
        "dd/MM/yyyy HH:mm",

        // Other common formats
        "EEE, dd MMM yyyy HH:mm:ss zzz", // RFC 2822
        "EEE, d MMM yyyy HH:mm:ss Z",    // RFC 2822 variant
        "yyyy/MM/dd",
        "yyyyMMdd",
    ]

    private static let locales = [
        Locale(identifier: "en_US"),
        Locale(identifier: "en_GB"),
        Locale(identifier: "en_US_POSIX"),
    ]

    private static func parseCommonFormats(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current

        for locale in locales {
            formatter.locale = locale

            for format in commonFormats {
                formatter.dateFormat = format
                if let date = formatter.date(from: string) {
                    return date
                }
            }
        }

        // Try lenient parsing
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        for locale in locales {
            formatter.locale = locale
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    // MARK: - Utilities

    /// Formats a date as ISO 8601 string.
    public static func formatISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
