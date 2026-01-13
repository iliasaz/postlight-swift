import Foundation

/// Converts HTML content to plain text.
///
/// Strips all HTML tags while preserving meaningful whitespace and structure.
public struct HTMLToText: Sendable {
    public init() {}

    /// Converts HTML string to plain text.
    ///
    /// - Parameter html: The HTML content to convert.
    /// - Returns: The plain text representation of the HTML.
    public func convert(_ html: String) throws -> String {
        let document = try Document(html: html)

        // Remove script and style elements first
        let scriptsAndStyles = try document.select("script, style, noscript")
        for element in scriptsAndStyles {
            try element.remove()
        }

        // Get body
        guard let body = document.body else {
            return ""
        }

        // Convert to text with proper spacing
        let text = try convertElement(body)

        // Clean up excessive whitespace
        return cleanText(text)
    }

    private func convertElement(_ element: Element) throws -> String {
        let tag = element.tagName.lowercased()

        // Skip hidden elements
        if element.hasClass("hidden") ||
           element.attrOrNil("aria-hidden") == "true" ||
           element.attrOrNil("style")?.contains("display: none") == true ||
           element.attrOrNil("style")?.contains("display:none") == true {
            return ""
        }

        switch tag {
        // Block elements that need line breaks
        case "p", "div", "article", "section", "main", "header", "footer", "aside", "nav":
            let content = try processChildren(element)
            return "\(content)\n\n"

        case "h1", "h2", "h3", "h4", "h5", "h6":
            let text = try element.text()
            return "\(text)\n\n"

        case "br":
            return "\n"

        case "hr":
            return "\n---\n\n"

        // Lists
        case "ul", "ol":
            return try convertList(element)

        case "li":
            let content = try processChildren(element)
            return "• \(content)\n"

        // Tables
        case "table":
            return try convertTable(element)

        case "tr":
            let cells = try element.select("td, th")
            let texts = try cells.map { try $0.text() }
            return texts.joined(separator: "\t") + "\n"

        // Blockquotes
        case "blockquote":
            let content = try processChildren(element)
            let lines = content.split(separator: "\n")
            return lines.map { "  \($0)" }.joined(separator: "\n") + "\n\n"

        // Code blocks
        case "pre":
            let text = try element.text()
            return "\n\(text)\n\n"

        case "code":
            return try element.text()

        // Links - include URL in parentheses
        case "a":
            let text = try element.text()
            if let href = element.attrOrNil("href"),
               !href.isEmpty,
               !href.hasPrefix("#"),
               !href.hasPrefix("javascript:") {
                // Only include URL if it's different from the text
                if !text.contains(href) && href.hasPrefix("http") {
                    return "\(text) (\(href))"
                }
            }
            return text

        // Images - include alt text
        case "img":
            if let alt = element.attrOrNil("alt"), !alt.isEmpty {
                return "[\(alt)]"
            }
            return ""

        // Inline elements
        case "span", "strong", "b", "em", "i", "u", "s", "del", "mark", "small", "sub", "sup":
            return try processChildren(element)

        // Figure with caption
        case "figure":
            return try processChildren(element) + "\n"

        case "figcaption":
            let text = try element.text()
            return "(\(text))\n"

        // Skip these elements entirely
        case "script", "style", "noscript", "iframe", "object", "embed", "form", "input", "button", "select", "textarea":
            return ""

        default:
            return try processChildren(element)
        }
    }

    private func processChildren(_ element: Element) throws -> String {
        let children = element.children()

        if children.isEmpty {
            return try element.text()
        }

        var result = ""
        for child in children {
            result += try convertElement(child)
        }

        // If we got nothing from children, fall back to text
        if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return try element.text()
        }

        return result
    }

    private func convertList(_ element: Element) throws -> String {
        var result = ""
        let items = try element.select(":scope > li")
        let isOrdered = element.tagName.lowercased() == "ol"

        for (index, item) in items.enumerated() {
            let content = try processChildren(item)
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

            if isOrdered {
                result += "\(index + 1). \(trimmed)\n"
            } else {
                result += "• \(trimmed)\n"
            }
        }

        return result + "\n"
    }

    private func convertTable(_ element: Element) throws -> String {
        var result = ""

        let rows = try element.select("tr")
        for row in rows {
            let cells = try row.select("td, th")
            let texts = try cells.map { try $0.text() }
            result += texts.joined(separator: "\t") + "\n"
        }

        return result + "\n"
    }

    private func cleanText(_ text: String) -> String {
        var result = text

        // Replace multiple spaces with single space
        result = result.replacingOccurrences(
            of: "[ \\t]+",
            with: " ",
            options: .regularExpression
        )

        // Replace more than 2 consecutive newlines with 2
        result = result.replacingOccurrences(
            of: "\\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        // Trim whitespace from each line
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        result = lines.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")

        // Final trim
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
