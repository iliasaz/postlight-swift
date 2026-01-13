import Foundation

/// Extracts the main content from an HTML document using scoring algorithms.
///
/// This is a port of the Postlight Parser's content extraction algorithm,
/// which uses various heuristics to identify the most likely article content.
public struct ContentExtractor: Sendable {
    /// Options for content extraction.
    public struct Options: Sendable {
        /// Remove elements with class/id matching unlikely content patterns.
        public var stripUnlikelyCandidates: Bool = true

        /// Use class/id hints to modify element scores.
        public var weightNodes: Bool = true

        /// Conditionally clean tags based on content analysis.
        public var cleanConditionally: Bool = true

        /// Creates default content extraction options.
        public init(
            stripUnlikelyCandidates: Bool = true,
            weightNodes: Bool = true,
            cleanConditionally: Bool = true
        ) {
            self.stripUnlikelyCandidates = stripUnlikelyCandidates
            self.weightNodes = weightNodes
            self.cleanConditionally = cleanConditionally
        }
    }

    public init() {}

    /// Extracts content from a document.
    public func extract(
        document: Document,
        title: String?,
        url: URL,
        options: Options = Options()
    ) throws -> String? {
        var opts = options

        // Try extraction with progressively relaxed options
        if let content = try attemptExtraction(document: document, title: title, url: url, options: opts) {
            return content
        }

        // Retry with stripUnlikelyCandidates disabled
        opts.stripUnlikelyCandidates = false
        if let content = try attemptExtraction(document: document, title: title, url: url, options: opts) {
            return content
        }

        // Retry with weightNodes disabled
        opts.weightNodes = false
        if let content = try attemptExtraction(document: document, title: title, url: url, options: opts) {
            return content
        }

        // Retry with cleanConditionally disabled
        opts.cleanConditionally = false
        return try attemptExtraction(document: document, title: title, url: url, options: opts)
    }

    private func attemptExtraction(
        document: Document,
        title: String?,
        url: URL,
        options: Options
    ) throws -> String? {
        // Clone the document to avoid modifying the original
        let html = try document.html()
        let workingDoc = try Document(html: html, baseURL: url)

        // Step 1: Strip unlikely candidates
        if options.stripUnlikelyCandidates {
            try stripUnlikelyCandidates(document: workingDoc)
        }

        // Step 2: Convert divs to paragraphs where appropriate
        try convertToParagraphs(document: workingDoc)

        // Step 3: Score content
        try scoreContent(document: workingDoc, weightNodes: options.weightNodes)

        // Step 4: Find top candidate
        guard let topCandidate = try findTopCandidate(document: workingDoc) else {
            return nil
        }

        // Step 5: Check if content is sufficient
        let text = try topCandidate.text()
        guard text.count >= ScoringConstants.minimumContentLength else {
            return nil
        }

        // Step 6: Clean and return content
        let cleanedContent = try cleanContent(
            element: topCandidate,
            document: workingDoc,
            title: title,
            url: url,
            cleanConditionally: options.cleanConditionally
        )

        return cleanedContent
    }

    // MARK: - Step 1: Strip Unlikely Candidates

    private func stripUnlikelyCandidates(document: Document) throws {
        let candidates = try document.select("*")

        for element in candidates {
            let className = element.className ?? ""
            let id = element.id ?? ""
            let combined = "\(className) \(id)"

            // Skip if whitelist match
            if ScoringConstants.candidatesWhitelistPattern.hasMatch(in: combined) {
                continue
            }

            // Remove if blacklist match
            if ScoringConstants.candidatesBlacklistPattern.hasMatch(in: combined) {
                // Don't remove essential elements
                let tag = element.tagName.lowercased()
                if !["html", "body", "article", "main"].contains(tag) {
                    try element.remove()
                }
            }
        }
    }

    // MARK: - Step 2: Convert to Paragraphs

    private func convertToParagraphs(document: Document) throws {
        let divs = try document.select("div")

        for div in divs {
            // Check if this div contains block-level elements
            let hasBlockElements = try !div.select(ScoringConstants.divToBlockTags).isEmpty

            if !hasBlockElements {
                // Convert to paragraph
                try convertNodeTo(div, tagName: "p")
            }
        }
    }

    private func convertNodeTo(_ element: Element, tagName: String) throws {
        let html = try element.html()
        try element.replaceWith("<\(tagName)>\(html)</\(tagName)>")
    }

    // MARK: - Step 3: Score Content

    private func scoreContent(document: Document, weightNodes: Bool) throws {
        // Give boost to hNews content selectors
        for (parentSelector, childSelector) in ScoringConstants.hNewsContentSelectors {
            let elements = try document.select("\(parentSelector) \(childSelector)")
            for element in elements {
                if let parent = element.parent() {
                    addScore(to: parent, amount: 80)
                }
            }
        }

        // Score paragraphs
        let paragraphs = try document.select("p, pre")

        for paragraph in paragraphs where paragraph.score == 0 {
            // Initialize score with weight
            let weight = weightNodes ? getWeight(element: paragraph) : 0
            paragraph.score = Double(weight)

            // Score based on content
            let score = scoreParagraph(paragraph)

            // Add to parent
            if let parent = paragraph.parent() {
                addScore(to: parent, amount: score)

                // Add half to grandparent
                if let grandparent = parent.parent() {
                    addScore(to: grandparent, amount: score / 2)
                }
            }
        }
    }

    private func getWeight(element: Element) -> Int {
        let className = element.className ?? ""
        let id = element.id ?? ""
        var score = 0

        // Check ID
        if !id.isEmpty {
            if ScoringConstants.positiveScorePattern.hasMatch(in: id) {
                score += 25
            }
            if ScoringConstants.negativeScorePattern.hasMatch(in: id) {
                score -= 25
            }
        }

        // Check class
        if !className.isEmpty && score == 0 {
            if ScoringConstants.positiveScorePattern.hasMatch(in: className) {
                score += 25
            }
            if ScoringConstants.negativeScorePattern.hasMatch(in: className) {
                score -= 25
            }
        }

        // Photo hints bonus
        if ScoringConstants.photoHintsPattern.hasMatch(in: className) {
            score += 10
        }

        // Readability asset bonus
        if ScoringConstants.readabilityAssetPattern.hasMatch(in: className) {
            score += 25
        }

        return score
    }

    private func scoreParagraph(_ element: Element) -> Double {
        let text = (try? element.text()) ?? ""

        // Base score
        var score: Double = 1

        // Comma bonus (indicates complex sentences)
        let commaCount = text.filter { $0 == "," }.count
        score += Double(commaCount)

        // Length bonus
        let length = text.count
        score += Double(min(length / 100, 3))

        return score
    }

    private func addScore(to element: Element, amount: Double) {
        element.score += amount
    }

    // MARK: - Step 4: Find Top Candidate

    private func findTopCandidate(document: Document) throws -> Element? {
        let scoredElements = try document.select("[score]")
        var topCandidate: Element?
        var topScore: Double = 0

        for element in scoredElements {
            let tag = element.tagName.lowercased()

            // Skip non-top-candidate tags
            if ScoringConstants.nonTopCandidateTags.contains(tag) {
                continue
            }

            let score = element.score
            if score > topScore {
                topScore = score
                topCandidate = element
            }
        }

        // Fallback to body
        if topCandidate == nil {
            topCandidate = document.body
        }

        // Merge siblings if beneficial
        if let candidate = topCandidate {
            return try mergeSiblings(candidate: candidate, topScore: topScore)
        }

        return topCandidate
    }

    private func mergeSiblings(candidate: Element, topScore: Double) throws -> Element {
        // Get siblings and check if they should be merged
        let siblings = candidate.siblings()
        var elementsToMerge: [Element] = [candidate]

        let threshold = topScore * 0.2 // Siblings need 20% of top score

        for sibling in siblings {
            if sibling.score >= threshold {
                elementsToMerge.append(sibling)
            }
        }

        // If only the candidate, return as-is
        if elementsToMerge.count == 1 {
            return candidate
        }

        // Wrap merged content in a div
        // For now, just return the candidate
        return candidate
    }

    // MARK: - Step 5: Clean Content

    private func cleanContent(
        element: Element,
        document: Document,
        title: String?,
        url: URL,
        cleanConditionally: Bool
    ) throws -> String {
        // Clean various elements
        try cleanImages(element: element)
        try makeLinksAbsolute(element: element, baseURL: url)
        try stripJunkTags(element: element)
        try cleanHOnes(element: element)
        try cleanHeaders(element: element, title: title)

        if cleanConditionally {
            try cleanTags(element: element)
        }

        try removeEmpty(element: element)
        try cleanAttributes(element: element)

        return try element.html()
    }

    private func cleanImages(element: Element) throws {
        let images = try element.select("img")
        for img in images {
            // Remove small/spacer images
            if let width = img.attrOrNil("width"), let w = Int(width), w < 10 {
                try img.remove()
                continue
            }
            if let height = img.attrOrNil("height"), let h = Int(height), h < 10 {
                try img.remove()
                continue
            }
        }
    }

    private func makeLinksAbsolute(element: Element, baseURL: URL) throws {
        let links = try element.select("a[href]")
        for link in links {
            if let href = link.attrOrNil("href"),
               !href.hasPrefix("http"),
               !href.hasPrefix("//"),
               let absoluteURL = URL(string: href, relativeTo: baseURL) {
                try link.attr("href", absoluteURL.absoluteString)
            }
        }

        let images = try element.select("img[src]")
        for img in images {
            if let src = img.attrOrNil("src"),
               !src.hasPrefix("http"),
               !src.hasPrefix("//"),
               !src.hasPrefix("data:"),
               let absoluteURL = URL(string: src, relativeTo: baseURL) {
                try img.attr("src", absoluteURL.absoluteString)
            }
        }
    }

    private func stripJunkTags(element: Element) throws {
        let junkTags = ["script", "style", "link", "noscript", "iframe", "object", "embed", "form", "input", "button", "textarea", "select"]
        for tag in junkTags {
            let elements = try element.select(tag)
            for el in elements {
                try el.remove()
            }
        }
    }

    private func cleanHOnes(element: Element) throws {
        let h1s = try element.select("h1")
        if h1s.count < 3 {
            // Remove H1s (they're likely the title)
            for h1 in h1s {
                try h1.remove()
            }
        } else {
            // Convert to H2s
            for h1 in h1s {
                try convertNodeTo(h1, tagName: "h2")
            }
        }
    }

    private func cleanHeaders(element: Element, title: String?) throws {
        guard let title = title else { return }

        let headers = try element.select("h1, h2, h3, h4, h5, h6")
        for header in headers {
            let headerText = try header.text()
            // Remove headers that match the title
            if headerText.lowercased() == title.lowercased() {
                try header.remove()
            }
        }
    }

    private func cleanTags(element: Element) throws {
        // Clean tables, lists, divs that look like navigation/ads
        let elementsToCheck = try element.select("table, ul, div")

        for el in elementsToCheck {
            let text = try el.text()
            let linkDensity = try calculateLinkDensity(element: el)

            // Remove if high link density and low text
            if linkDensity > 0.5 && text.count < 500 {
                try el.remove()
            }
        }
    }

    private func calculateLinkDensity(element: Element) throws -> Double {
        let text = try element.text()
        guard !text.isEmpty else { return 0 }

        let links = try element.select("a")
        var linkLength = 0
        for link in links {
            linkLength += (try? link.text().count) ?? 0
        }

        return Double(linkLength) / Double(text.count)
    }

    private func removeEmpty(element: Element) throws {
        let paragraphs = try element.select("p")
        for p in paragraphs {
            let text = try p.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                try p.remove()
            }
        }
    }

    private func cleanAttributes(element: Element) throws {
        // Keep only essential attributes
        let allowedAttributes = ["href", "src", "alt", "title", "class", "id"]

        func cleanElement(_ el: Element) throws {
            let attrs = el.attributes()
            for (name, _) in attrs {
                if !allowedAttributes.contains(name) && !name.hasPrefix("data-") {
                    try el.removeAttr(name)
                }
            }

            for child in el.children() {
                try cleanElement(child)
            }
        }

        try cleanElement(element)
    }
}
