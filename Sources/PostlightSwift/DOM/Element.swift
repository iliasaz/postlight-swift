import Foundation
import SwiftSoup

/// A wrapper around SwiftSoup.Element providing a jQuery-like interface.
public final class Element: @unchecked Sendable {
    /// The underlying SwiftSoup element.
    internal let element: SwiftSoup.Element

    /// Reference to the parent document.
    internal weak var document: Document?

    /// Creates an Element wrapper.
    internal init(element: SwiftSoup.Element, document: Document?) {
        self.element = element
        self.document = document
    }

    // MARK: - Basic Properties

    /// The tag name of this element (lowercase).
    public var tagName: String {
        element.tagName()
    }

    /// The element's ID attribute, if present.
    public var id: String? {
        let id = element.id()
        return id.isEmpty ? nil : id
    }

    /// The element's class attribute, if present.
    public var className: String? {
        let cls = try? element.className()
        return cls?.isEmpty == false ? cls : nil
    }

    // MARK: - Content

    /// Gets the text content of this element and its descendants.
    public func text() throws -> String {
        try element.text()
    }

    /// Gets the inner HTML of this element.
    public func html() throws -> String {
        try element.html()
    }

    /// Gets the outer HTML of this element (including the element itself).
    public func outerHtml() throws -> String {
        try element.outerHtml()
    }

    /// Sets the inner HTML of this element.
    @discardableResult
    public func html(_ html: String) throws -> Element {
        try element.html(html)
        return self
    }

    // MARK: - Attributes

    /// Gets an attribute value by name.
    public func attr(_ name: String) throws -> String {
        try element.attr(name)
    }

    /// Gets an attribute value, returning nil if empty or not present.
    public func attrOrNil(_ name: String) -> String? {
        let value = try? element.attr(name)
        return value?.isEmpty == false ? value : nil
    }

    /// Sets an attribute value.
    @discardableResult
    public func attr(_ name: String, _ value: String) throws -> Element {
        try element.attr(name, value)
        return self
    }

    /// Removes an attribute.
    @discardableResult
    public func removeAttr(_ name: String) throws -> Element {
        try element.removeAttr(name)
        return self
    }

    /// Checks if the element has an attribute.
    public func hasAttr(_ name: String) -> Bool {
        element.hasAttr(name)
    }

    /// Gets all attributes as a dictionary.
    public func attributes() -> [String: String] {
        var attrs: [String: String] = [:]
        if let attributes = element.getAttributes() {
            for attr in attributes {
                attrs[attr.getKey()] = attr.getValue()
            }
        }
        return attrs
    }

    // MARK: - Classes

    /// Checks if the element has a specific class.
    public func hasClass(_ className: String) -> Bool {
        element.hasClass(className)
    }

    /// Adds a class to this element.
    @discardableResult
    public func addClass(_ className: String) throws -> Element {
        try element.addClass(className)
        return self
    }

    /// Removes a class from this element.
    @discardableResult
    public func removeClass(_ className: String) throws -> Element {
        try element.removeClass(className)
        return self
    }

    // MARK: - Tree Navigation

    /// Gets the parent element.
    public func parent() -> Element? {
        element.parent().map { Element(element: $0, document: document) }
    }

    /// Gets all child elements.
    public func children() -> [Element] {
        element.children().array().map { Element(element: $0, document: document) }
    }

    /// Gets all sibling elements.
    public func siblings() -> [Element] {
        element.siblingElements().array().map { Element(element: $0, document: document) }
    }

    /// Gets the next sibling element.
    public func nextSibling() -> Element? {
        (try? element.nextElementSibling()).map { Element(element: $0, document: document) }
    }

    /// Gets the previous sibling element.
    public func previousSibling() -> Element? {
        (try? element.previousElementSibling()).map { Element(element: $0, document: document) }
    }

    // MARK: - Selection

    /// Selects descendants matching a CSS selector.
    public func select(_ selector: String) throws -> [Element] {
        try element.select(selector).array().map { Element(element: $0, document: document) }
    }

    /// Selects the first descendant matching a CSS selector.
    public func selectFirst(_ selector: String) throws -> Element? {
        guard let found = try element.select(selector).first() else { return nil }
        return Element(element: found, document: document)
    }

    // MARK: - Manipulation

    /// Removes this element from the DOM.
    @discardableResult
    public func remove() throws -> Element {
        try element.remove()
        return self
    }

    /// Wraps this element in another element.
    @discardableResult
    public func wrap(_ html: String) throws -> Element {
        try element.wrap(html)
        return self
    }

    /// Replaces this element with the given HTML.
    @discardableResult
    public func replaceWith(_ html: String) throws -> Element {
        // SwiftSoup doesn't have a direct replaceWith, so we work around it
        try element.before(html)
        try element.remove()
        return self
    }

    /// Appends HTML to this element's children.
    @discardableResult
    public func append(_ html: String) throws -> Element {
        try element.append(html)
        return self
    }

    /// Prepends HTML to this element's children.
    @discardableResult
    public func prepend(_ html: String) throws -> Element {
        try element.prepend(html)
        return self
    }

    /// Inserts HTML before this element.
    @discardableResult
    public func before(_ html: String) throws -> Element {
        try element.before(html)
        return self
    }

    /// Inserts HTML after this element.
    @discardableResult
    public func after(_ html: String) throws -> Element {
        try element.after(html)
        return self
    }

    // MARK: - Custom Data

    /// Score attribute used by the content extraction algorithm.
    public var score: Double {
        get {
            Double(attrOrNil("score") ?? "0") ?? 0
        }
        set {
            _ = try? attr("score", String(newValue))
        }
    }
}

// MARK: - Equatable

extension Element: Equatable {
    public static func == (lhs: Element, rhs: Element) -> Bool {
        lhs.element === rhs.element
    }
}

// MARK: - Hashable

extension Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(element))
    }
}
