public protocol DocumentRenderer: Sendable {
    func render(_ document: Document) -> String
}

extension DocumentRenderer {
    /// Shared skeleton: one rendered chunk per block, separated by a blank line.
    func renderBlocks(_ document: Document, _ renderBlock: (Block) -> String) -> String {
        document.blocks.map(renderBlock).joined(separator: "\n\n")
    }
}
