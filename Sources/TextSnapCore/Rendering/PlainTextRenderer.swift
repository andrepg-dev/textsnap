public struct PlainTextRenderer: DocumentRenderer {
    private static let nestingIndent = "  "

    public init() {}

    public func render(_ document: Document) -> String {
        renderBlocks(document) { block in
            switch block {
            case .heading(_, let text):
                text
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
        case .bullet: return indent + "• " + item.text
        case .ordered(let marker): return indent + marker + " " + item.text
        }
    }
}
