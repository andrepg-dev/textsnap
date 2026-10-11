/// Detects list markers at the start of a recognized line.
enum ListMarkerParser {
    /// Glyphs that are unambiguously bullets, even when OCR glues them to the text.
    private static let glyphBullets: Set<Character> = [
        "•", "◦", "▪", "▫", "●", "○", "■", "□", "‣", "⁃", "∙", "·", "➢", "➤", "►", "▸", "▹", "✓", "✔",
    ]
    /// Characters that only act as bullets when followed by whitespace.
    private static let textBullets: Set<Character> = ["-", "*", "+", "–", "—"]

    static func parse(_ text: String) -> (marker: ListMarker, content: String)? {
        guard let first = text.first else { return nil }

        if glyphBullets.contains(first) {
            return item(.bullet, content: text.dropFirst())
        }
        if textBullets.contains(first), text.dropFirst().first?.isWhitespace == true {
            return item(.bullet, content: text.dropFirst())
        }
        return parseOrdered(text)
    }

    /// Accepts `1.` `12)` `a)` `a.` `B)` — but not `B.`, which is far more often an initial ("J. Smith").
    private static func parseOrdered(_ text: String) -> (marker: ListMarker, content: String)? {
        let digits = text.prefix { $0.isASCII && $0.isNumber }
        let label: Substring
        if (1...3).contains(digits.count) {
            label = digits
        } else if let first = text.first, first.isASCII, first.isLetter {
            label = text.prefix(1)
        } else {
            return nil
        }

        let afterLabel = text[label.endIndex...]
        guard let delimiter = afterLabel.first, delimiter == "." || delimiter == ")" else { return nil }
        if delimiter == ".", label.first?.isUppercase == true { return nil }

        let rest = afterLabel.dropFirst()
        guard rest.first?.isWhitespace == true else { return nil }
        return item(.ordered(String(label) + String(delimiter)), content: rest)
    }

    private static func item(_ marker: ListMarker, content: Substring) -> (marker: ListMarker, content: String)? {
        let trimmed = content.trimmingLeadingWhitespace()
        guard !trimmed.isEmpty else { return nil }
        return (marker, String(trimmed))
    }
}

extension Substring {
    func trimmingLeadingWhitespace() -> Substring {
        drop { $0.isWhitespace }
    }
}
