/// Entry point of the core module: OCR lines in, clipboard-ready text out.
public struct TextFormatter: Sendable {
    private let analyzer: LayoutAnalyzer

    public init(analyzer: LayoutAnalyzer = LayoutAnalyzer()) {
        self.analyzer = analyzer
    }

    public func format(_ lines: [TextLine], as format: OutputFormat) -> String {
        format.renderer.render(analyzer.analyze(lines))
    }
}
