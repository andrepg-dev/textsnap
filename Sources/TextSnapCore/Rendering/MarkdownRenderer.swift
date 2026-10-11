public struct MarkdownRenderer: DocumentRenderer {
    /// Four spaces nest correctly under both `- ` and `10. ` parents in CommonMark.
    private static let nestingIndent = "    "

    public init() {}

    public func render(_ document: Document) -> String {
        renderBlocks(document) { block in
            switch block {
            case .heading(let level, let text):
                String(repeating: "#", count: level) + " " + text
            case .paragraph(let lines):
                lines.joined(separator: "\n")
            case .list(let items):
                items.map(render).joined(separator: "\n")
            }
        }
    }

    private func render(_ item: ListItem) -> String {
        let indent = String(repeating: Self.nestingIndent, count: item.level)
        switch item.marker {
        case .bullet:
            return indent + "- " + item.text
        case .ordered(let marker) where marker.first?.isNumber == true:
            return indent + marker + " " + item.text
        case .ordered(let marker):
            // Markdown has no lettered lists; keep the letter inside a bullet.
            return indent + "- " + marker + " " + item.text
        }
    }
}
