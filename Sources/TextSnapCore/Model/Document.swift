/// Structured representation of the text found in a capture,
/// independent of how it will eventually be serialized.
public struct Document: Sendable, Equatable {
    public var blocks: [Block]

    public init(blocks: [Block]) {
        self.blocks = blocks
    }

    public var isEmpty: Bool { blocks.isEmpty }
}

public enum Block: Sendable, Equatable {
    /// `level` starts at 1 for the most prominent heading.
    case heading(level: Int, text: String)
    /// Each element is a hard line; soft-wrapped lines are already joined.
    case paragraph(lines: [String])
    case list(items: [ListItem])
}

public struct ListItem: Sendable, Equatable {
    public var marker: ListMarker
    public var text: String
    /// Nesting depth, 0 for top-level items.
    public var level: Int

    public init(marker: ListMarker, text: String, level: Int = 0) {
        self.marker = marker
        self.text = text
        self.level = level
    }
}

public enum ListMarker: Sendable, Equatable {
    case bullet
    /// The marker exactly as written, e.g. `"1."`, `"2)"`, `"a)"`.
    case ordered(String)
}
