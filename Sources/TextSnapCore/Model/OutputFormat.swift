public enum OutputFormat: String, Sendable, CaseIterable {
    case markdown
    case plainText

    public var renderer: any DocumentRenderer {
        switch self {
        case .markdown: MarkdownRenderer()
        case .plainText: PlainTextRenderer()
        }
    }
}
