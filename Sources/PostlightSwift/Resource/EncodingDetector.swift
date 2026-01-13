import Foundation

/// Detects and handles character encoding for HTML content.
///
/// Supports detection from:
/// - HTTP Content-Type header
/// - HTML meta charset tags
/// - BOM (Byte Order Mark)
/// - Content analysis heuristics
public struct EncodingDetector: Sendable {
    public init() {}

    /// Detects the encoding of HTML data.
    ///
    /// - Parameters:
    ///   - data: The raw HTML data.
    ///   - contentType: Optional Content-Type header value.
    /// - Returns: The detected encoding, or UTF-8 as fallback.
    public func detect(data: Data, contentType: String? = nil) -> String.Encoding {
        // 1. Check BOM first (most reliable)
        if let bomEncoding = detectBOM(data) {
            return bomEncoding
        }

        // 2. Check HTTP Content-Type header
        if let contentType = contentType,
           let headerEncoding = parseContentTypeEncoding(contentType) {
            return headerEncoding
        }

        // 3. Check HTML meta tags (need to parse as ASCII/UTF-8 first)
        if let metaEncoding = detectMetaEncoding(data) {
            return metaEncoding
        }

        // 4. Use heuristics
        if let heuristicEncoding = detectByHeuristics(data) {
            return heuristicEncoding
        }

        // 5. Default to UTF-8
        return .utf8
    }

    /// Decodes data with automatic encoding detection.
    ///
    /// - Parameters:
    ///   - data: The raw data to decode.
    ///   - contentType: Optional Content-Type header value.
    /// - Returns: The decoded string, or nil if decoding fails.
    public func decode(data: Data, contentType: String? = nil) -> String? {
        let encoding = detect(data: data, contentType: contentType)

        // Try detected encoding first
        if let string = String(data: data, encoding: encoding) {
            return string
        }

        // Try common fallback encodings
        let fallbacks: [String.Encoding] = [
            .utf8,
            .isoLatin1,
            .windowsCP1252,
            .ascii,
        ]

        for fallback in fallbacks {
            if let string = String(data: data, encoding: fallback) {
                return string
            }
        }

        return nil
    }

    // MARK: - BOM Detection

    private func detectBOM(_ data: Data) -> String.Encoding? {
        guard data.count >= 2 else { return nil }

        let bytes = Array(data.prefix(4))

        // UTF-8 BOM: EF BB BF
        if bytes.count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF {
            return .utf8
        }

        // UTF-32 BE BOM: 00 00 FE FF
        if bytes.count >= 4 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF {
            return .utf32BigEndian
        }

        // UTF-32 LE BOM: FF FE 00 00
        if bytes.count >= 4 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00 {
            return .utf32LittleEndian
        }

        // UTF-16 BE BOM: FE FF
        if bytes[0] == 0xFE && bytes[1] == 0xFF {
            return .utf16BigEndian
        }

        // UTF-16 LE BOM: FF FE
        if bytes[0] == 0xFF && bytes[1] == 0xFE {
            return .utf16LittleEndian
        }

        return nil
    }

    // MARK: - Content-Type Header Parsing

    private func parseContentTypeEncoding(_ contentType: String) -> String.Encoding? {
        // Extract charset from Content-Type: text/html; charset=utf-8
        let charsetPattern = /charset\s*=\s*["']?([^"';\s]+)/

        guard let match = contentType.lowercased().firstMatch(of: charsetPattern) else {
            return nil
        }

        let charset = String(match.1)
        return encodingFromName(charset)
    }

    // MARK: - Meta Tag Detection

    private func detectMetaEncoding(_ data: Data) -> String.Encoding? {
        // Try to read first 1024 bytes as ASCII to find meta tags
        let prefix = data.prefix(1024)
        guard let html = String(data: prefix, encoding: .ascii) ?? String(data: prefix, encoding: .utf8) else {
            return nil
        }

        let lowercased = html.lowercased()

        // Look for <meta charset="...">
        let charsetPattern = /<meta[^>]+charset\s*=\s*["']?([^"'>\s]+)/
        if let match = lowercased.firstMatch(of: charsetPattern) {
            let charset = String(match.1)
            return encodingFromName(charset)
        }

        // Look for <meta http-equiv="Content-Type" content="text/html; charset=...">
        let httpEquivPattern = /<meta[^>]+http-equiv\s*=\s*["']?content-type["']?[^>]+content\s*=\s*["']?[^"']*charset=([^"'>\s;]+)/
        if let match = lowercased.firstMatch(of: httpEquivPattern) {
            let charset = String(match.1)
            return encodingFromName(charset)
        }

        // Also check reverse order (content before http-equiv)
        let httpEquivPattern2 = /<meta[^>]+content\s*=\s*["']?[^"']*charset=([^"'>\s;]+)[^>]+http-equiv\s*=\s*["']?content-type/
        if let match = lowercased.firstMatch(of: httpEquivPattern2) {
            let charset = String(match.1)
            return encodingFromName(charset)
        }

        return nil
    }

    // MARK: - Heuristic Detection

    private func detectByHeuristics(_ data: Data) -> String.Encoding? {
        // Check if it's valid UTF-8
        if isValidUTF8(data) {
            return .utf8
        }

        // Check for high bytes that might indicate Windows-1252 or Latin-1
        let hasHighBytes = data.contains { $0 > 127 }
        if hasHighBytes {
            // Try Windows-1252 first (more common than Latin-1 on web)
            if String(data: data, encoding: .windowsCP1252) != nil {
                return .windowsCP1252
            }

            if String(data: data, encoding: .isoLatin1) != nil {
                return .isoLatin1
            }
        }

        return nil
    }

    private func isValidUTF8(_ data: Data) -> Bool {
        var index = 0
        let bytes = Array(data)

        while index < bytes.count {
            let byte = bytes[index]

            if byte < 0x80 {
                // ASCII
                index += 1
            } else if byte < 0xC0 {
                // Invalid start byte
                return false
            } else if byte < 0xE0 {
                // 2-byte sequence
                if index + 1 >= bytes.count || !isContinuationByte(bytes[index + 1]) {
                    return false
                }
                index += 2
            } else if byte < 0xF0 {
                // 3-byte sequence
                if index + 2 >= bytes.count ||
                   !isContinuationByte(bytes[index + 1]) ||
                   !isContinuationByte(bytes[index + 2]) {
                    return false
                }
                index += 3
            } else if byte < 0xF8 {
                // 4-byte sequence
                if index + 3 >= bytes.count ||
                   !isContinuationByte(bytes[index + 1]) ||
                   !isContinuationByte(bytes[index + 2]) ||
                   !isContinuationByte(bytes[index + 3]) {
                    return false
                }
                index += 4
            } else {
                return false
            }
        }

        return true
    }

    private func isContinuationByte(_ byte: UInt8) -> Bool {
        (byte & 0xC0) == 0x80
    }

    // MARK: - Encoding Name Mapping

    private func encodingFromName(_ name: String) -> String.Encoding? {
        let normalized = name.lowercased().replacingOccurrences(of: "-", with: "")

        switch normalized {
        case "utf8":
            return .utf8
        case "utf16", "utf16le":
            return .utf16LittleEndian
        case "utf16be":
            return .utf16BigEndian
        case "utf32", "utf32le":
            return .utf32LittleEndian
        case "utf32be":
            return .utf32BigEndian
        case "ascii", "usascii":
            return .ascii
        case "iso88591", "latin1", "iso885915":
            return .isoLatin1
        case "iso88592":
            return .isoLatin2
        case "windows1250", "cp1250":
            return .windowsCP1250
        case "windows1251", "cp1251":
            return .windowsCP1251
        case "windows1252", "cp1252":
            return .windowsCP1252
        case "windows1253", "cp1253":
            return .windowsCP1253
        case "windows1254", "cp1254":
            return .windowsCP1254
        case "shiftjis", "sjis", "xsjis":
            return .shiftJIS
        case "eucjp", "xeucjp":
            return .japaneseEUC
        case "iso2022jp":
            return .iso2022JP
        case "gb2312", "gbk", "gb18030":
            // Foundation doesn't have direct GB2312, use closest
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        case "big5":
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue)))
        case "euckr":
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.EUC_KR.rawValue)))
        case "koi8r":
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.KOI8_R.rawValue)))
        default:
            return nil
        }
    }

    // MARK: - Public Encoding Name Lookup

    /// Converts an encoding name string to a Swift String.Encoding.
    ///
    /// - Parameter name: The encoding name (e.g., "utf-8", "iso-8859-1").
    /// - Returns: The corresponding encoding, or nil if not recognized.
    public func encoding(fromName name: String) -> String.Encoding? {
        encodingFromName(name)
    }
}
