import Foundation

/// Converts HTML content to Markdown format.
///
/// Handles common HTML elements and converts them to their Markdown equivalents.
public struct HTMLToMarkdown: Sendable {
    public init() {}

    /// Converts HTML string to Markdown.
    ///
    /// - Parameter html: The HTML content to convert.
    /// - Returns: The Markdown representation of the HTML.
    public func convert(_ html: String) throws -> String {
        let document = try Document(html: html)
        guard let body = document.body else {
            // If no body, return empty string
            return ""
        }
        let result = try convertElement(body)
        return normalizeWhitespace(result)
    }

    /// Normalizes whitespace in the final markdown output.
    private func normalizeWhitespace(_ text: String) -> String {
        var result = text

        // Replace multiple consecutive newlines with double newlines
        result = result.replacingOccurrences(
            of: "\\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        // Trim whitespace from each line while preserving line structure
        let lines = result.components(separatedBy: "\n")
        result = lines.map { line in
            // Preserve intentional indentation for code blocks, but trim other lines
            if line.hasPrefix("```") || line.hasPrefix("    ") || line.hasPrefix("\t") {
                return line
            }
            return line.trimmingCharacters(in: .whitespaces)
        }.joined(separator: "\n")

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func convertElement(_ element: Element?) throws -> String {
        guard let element = element else { return "" }

        var result = ""

        // Get all child nodes including text nodes
        let nodes = element.childNodes()

        if nodes.isEmpty {
            // No children, get text content
            result = try element.text()
        } else {
            // Process each node (text or element)
            for node in nodes {
                if node.isElement, let childElement = node.element {
                    result += try convertNode(childElement)
                } else {
                    // Text node - normalize whitespace (collapse multiple spaces to one)
                    let normalizedText = node.text.replacingOccurrences(
                        of: "\\s+",
                        with: " ",
                        options: .regularExpression
                    )
                    result += normalizedText
                }
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func convertNode(_ element: Element) throws -> String {
        let tag = element.tagName.lowercased()

        // Skip ad-related elements and other promotional noise
        if let className = element.className {
            let skipPatterns = ["ad-unit", "ad-slot", "advertisement", "sponsored", "promo", "inline-cta"]
            for pattern in skipPatterns {
                if className.contains(pattern) {
                    return ""
                }
            }
        }

        switch tag {
        // Headers
        case "h1":
            return "# \(try element.text())\n\n"
        case "h2":
            return "## \(try element.text())\n\n"
        case "h3":
            return "### \(try element.text())\n\n"
        case "h4":
            return "#### \(try element.text())\n\n"
        case "h5":
            return "##### \(try element.text())\n\n"
        case "h6":
            return "###### \(try element.text())\n\n"

        // Paragraphs and line breaks
        case "p":
            let content = try convertChildren(element)
            return "\(content)\n\n"
        case "br":
            return "  \n"

        // Text formatting
        case "strong", "b":
            let content = try convertChildren(element)
            return "**\(content)**"
        case "em", "i":
            let content = try convertChildren(element)
            return "*\(content)*"
        case "code":
            let text = try element.text()
            return "`\(text)`"
        case "del", "s", "strike":
            let content = try convertChildren(element)
            return "~~\(content)~~"

        // Links and images
        case "a":
            let text = try convertChildren(element)
            let href = element.attrOrNil("href") ?? ""
            let title = element.attrOrNil("title")
            if let title = title, !title.isEmpty {
                return "[\(text)](\(href) \"\(title)\")"
            }
            return "[\(text)](\(href))"
        case "img":
            let alt = element.attrOrNil("alt") ?? ""
            let src = element.attrOrNil("src") ?? ""
            let title = element.attrOrNil("title")
            if let title = title, !title.isEmpty {
                return "![\(alt)](\(src) \"\(title)\")"
            }
            return "![\(alt)](\(src))"

        // Lists
        case "ul":
            return try convertUnorderedList(element)
        case "ol":
            return try convertOrderedList(element)
        case "li":
            let content = try convertChildren(element)
            return content

        // Blockquote
        case "blockquote":
            let content = try convertChildren(element)
            let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            let quoted = lines.map { "> \($0)" }.joined(separator: "\n")
            return "\(quoted)\n\n"

        // Code blocks
        case "pre":
            let code = try element.text()
            let language = detectLanguage(element)
            return "```\(language)\n\(code)\n```\n\n"

        // Horizontal rule
        case "hr":
            return "---\n\n"

        // Tables
        case "table":
            return try convertTable(element)

        // Div, article, section - just process children
        case "div", "article", "section", "main", "span", "figure", "figcaption":
            return try convertChildren(element)

        // Skip these elements
        case "script", "style", "nav", "aside", "footer", "header":
            return ""

        default:
            // For unknown elements, just convert children
            return try convertChildren(element)
        }
    }

    private func convertChildren(_ element: Element) throws -> String {
        var result = ""

        // Get all child nodes including text nodes
        let nodes = element.childNodes()

        // If no nodes, return text content
        if nodes.isEmpty {
            return try element.text()
        }

        // Process each node (text or element)
        for node in nodes {
            if node.isElement, let childElement = node.element {
                result += try convertNode(childElement)
            } else {
                // Text node - normalize whitespace (collapse multiple spaces to one)
                let normalizedText = node.text.replacingOccurrences(
                    of: "\\s+",
                    with: " ",
                    options: .regularExpression
                )
                result += normalizedText
            }
        }

        return result
    }

    private func convertUnorderedList(_ element: Element) throws -> String {
        var result = ""
        let items = try element.select("li")

        for item in items {
            let content = try convertChildren(item)
            let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
            if let first = lines.first {
                result += "- \(first)\n"
                for line in lines.dropFirst() {
                    result += "  \(line)\n"
                }
            }
        }

        return result + "\n"
    }

    private func convertOrderedList(_ element: Element) throws -> String {
        var result = ""
        let items = try element.select("li")

        for (index, item) in items.enumerated() {
            let content = try convertChildren(item)
            let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
            if let first = lines.first {
                result += "\(index + 1). \(first)\n"
                for line in lines.dropFirst() {
                    result += "   \(line)\n"
                }
            }
        }

        return result + "\n"
    }

    private func convertTable(_ element: Element) throws -> String {
        var result = ""

        // Get header row
        let headerCells = try element.select("thead th, thead td, tr:first-child th")
        if !headerCells.isEmpty {
            let headers = try headerCells.map { try $0.text() }
            result += "| \(headers.joined(separator: " | ")) |\n"
            result += "| \(headers.map { _ in "---" }.joined(separator: " | ")) |\n"
        }

        // Get body rows
        let rows = try element.select("tbody tr, tr")
        for row in rows {
            let cells = try row.select("td")
            if !cells.isEmpty {
                let cellTexts = try cells.map { try $0.text() }
                result += "| \(cellTexts.joined(separator: " | ")) |\n"
            }
        }

        return result + "\n"
    }

    private func detectLanguage(_ element: Element) -> String {
        // Check for language class
        if let className = element.className {
            let patterns = [
                /language-(\w+)/,
                /lang-(\w+)/,
                /(\w+)-code/,
            ]

            for pattern in patterns {
                if let match = className.firstMatch(of: pattern) {
                    return String(match.1)
                }
            }
        }

        // Check code child element
        if let code = try? element.selectFirst("code"),
           let codeClass = code.className {
            let patterns = [
                /language-(\w+)/,
                /lang-(\w+)/,
            ]

            for pattern in patterns {
                if let match = codeClass.firstMatch(of: pattern) {
                    return String(match.1)
                }
            }
        }

        return ""
    }
}
