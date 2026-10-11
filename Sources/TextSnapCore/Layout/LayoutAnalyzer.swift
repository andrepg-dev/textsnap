import CoreGraphics

/// Rebuilds document structure (headings, paragraphs, nested lists) from the
/// geometry of OCR lines.
///
/// Every threshold is expressed relative to the body text height, so the
/// analysis behaves the same on a Retina capture as on a tiny screenshot.
public struct LayoutAnalyzer: Sendable {
    public struct Tuning: Sendable {
        /// Line height ratios (vs. body text) from which a line is treated as a heading.
        public var headingLevel1Ratio: CGFloat = 1.6
        public var headingLevel2Ratio: CGFloat = 1.3
        /// Maximum vertical gap between two lines of the same paragraph.
        public var paragraphLineGap: CGFloat = 0.7
        /// Maximum height difference between two lines of the same paragraph.
        public var paragraphHeightTolerance: CGFloat = 0.35
        /// How far right of its bullet a line must start to continue a list item.
        public var continuationIndent: CGFloat = 0.3
        public var continuationGap: CGFloat = 0.8
        /// Minimum horizontal offset between two list nesting levels.
        public var nestingStep: CGFloat = 0.6

        public init() {}
    }

    public var tuning: Tuning
    private let rowAssembler = RowAssembler()

    public init(tuning: Tuning = Tuning()) {
        self.tuning = tuning
    }

    public func analyze(_ fragments: [TextLine]) -> Document {
        let lines = rowAssembler.assemble(fragments)
        guard let bodyHeight = Self.medianHeight(of: lines), bodyHeight > 0 else {
            return Document(blocks: [])
        }

        var builder = BlockBuilder(bodyHeight: bodyHeight, tuning: tuning)
        for line in lines {
            builder.consume(line)
        }
        return Document(blocks: builder.finish())
    }

    private static func medianHeight(of lines: [TextLine]) -> CGFloat? {
        let heights = lines.map(\.frame.height).sorted()
        guard !heights.isEmpty else { return nil }
        return heights[heights.count / 2]
    }
}

// MARK: - Block building

/// Single forward pass over lines; keeps the block under construction open
/// until a line arrives that cannot belong to it.
private struct BlockBuilder {
    private enum LineKind {
        case heading(level: Int)
        case listItem(marker: ListMarker, content: String)
        case text
    }

    private struct PendingItem {
        var marker: ListMarker
        var text: String
        /// Union of every line of the item; `minX` is where the marker sits.
        var frame: CGRect
    }

    private enum Pending {
        case heading(level: Int, text: String)
        case paragraph([TextLine])
        case list([PendingItem])
    }

    let bodyHeight: CGFloat
    let tuning: LayoutAnalyzer.Tuning

    private var blocks: [Block] = []
    private var pending: Pending?
    private var previousFrame: CGRect?

    init(bodyHeight: CGFloat, tuning: LayoutAnalyzer.Tuning) {
        self.bodyHeight = bodyHeight
        self.tuning = tuning
    }

    mutating func consume(_ line: TextLine) {
        let gap = previousFrame.map { line.frame.minY - $0.maxY } ?? .infinity
        defer { previousFrame = line.frame }

        switch classify(line) {
        case .heading(let level):
            if case .heading(level, let text)? = pending, gap < tuning.paragraphLineGap * line.frame.height {
                pending = .heading(level: level, text: TextJoiner.join(text, line.text))
            } else {
                start(.heading(level: level, text: line.text))
            }

        case .listItem(let marker, let content):
            let item = PendingItem(marker: marker, text: content, frame: line.frame)
            if case .list(var items)? = pending {
                items.append(item)
                pending = .list(items)
            } else {
                start(.list([item]))
            }

        case .text:
            if case .list(var items)? = pending, let last = items.last, continues(last, with: line, gap: gap) {
                items[items.count - 1].text = TextJoiner.join(last.text, line.text)
                items[items.count - 1].frame = last.frame.union(line.frame)
                pending = .list(items)
            } else if case .paragraph(var lines)? = pending, let last = lines.last, continues(last, with: line, gap: gap) {
                lines.append(line)
                pending = .paragraph(lines)
            } else {
                start(.paragraph([line]))
            }
        }
    }

    mutating func finish() -> [Block] {
        flush()
        return blocks
    }

    // MARK: Classification

    private func classify(_ line: TextLine) -> LineKind {
        if let (marker, content) = ListMarkerParser.parse(line.text) {
            return .listItem(marker: marker, content: content)
        }
        let ratio = line.frame.height / bodyHeight
        if ratio >= tuning.headingLevel1Ratio { return .heading(level: 1) }
        if ratio >= tuning.headingLevel2Ratio { return .heading(level: 2) }
        return .text
    }

    /// A wrapped list item: indented past its marker and tight against the line above.
    private func continues(_ item: PendingItem, with line: TextLine, gap: CGFloat) -> Bool {
        line.frame.minX > item.frame.minX + tuning.continuationIndent * bodyHeight
            && gap < tuning.continuationGap * bodyHeight
    }

    private func continues(_ previous: TextLine, with line: TextLine, gap: CGFloat) -> Bool {
        gap < tuning.paragraphLineGap * bodyHeight
            && abs(line.frame.height - previous.frame.height) < tuning.paragraphHeightTolerance * bodyHeight
    }

    // MARK: Emission

    private mutating func start(_ block: Pending) {
        flush()
        pending = block
    }

    private mutating func flush() {
        guard let pending else { return }
        self.pending = nil

        switch pending {
        case .heading(let level, let text):
            blocks.append(.heading(level: level, text: text))
        case .paragraph(let lines):
            blocks.append(.paragraph(lines: hardLines(of: lines)))
        case .list(let items):
            blocks.append(.list(items: nested(items)))
        }
    }

    /// Joins lines that were soft-wrapped by the layout and keeps intentional breaks.
    ///
    /// A line counts as wrapped when the next line's first word would not have
    /// fit in the space left before the paragraph's right edge.
    private func hardLines(of lines: [TextLine]) -> [String] {
        let rightEdge = lines.map(\.frame.maxX).max() ?? 0
        var result: [String] = []
        var current = ""

        for (index, line) in lines.enumerated() {
            current = TextJoiner.join(current, line.text)
            let next = lines.indices.contains(index + 1) ? lines[index + 1] : nil
            if let next, wraps(line, before: next, rightEdge: rightEdge) { continue }
            result.append(current)
            current = ""
        }
        return result
    }

    private func wraps(_ line: TextLine, before next: TextLine, rightEdge: CGFloat) -> Bool {
        let characterWidth = line.frame.width / CGFloat(max(line.text.count, 1))
        let nextWordLength = next.text.prefix { !$0.isWhitespace }.count
        let neededWidth = CGFloat(nextWordLength + 1) * characterWidth
        return line.frame.maxX + neededWidth > rightEdge
    }

    /// Assigns nesting levels by clustering marker positions into indentation stops.
    private func nested(_ items: [PendingItem]) -> [ListItem] {
        let step = tuning.nestingStep * bodyHeight
        var stops: [CGFloat] = []
        for x in items.map(\.frame.minX).sorted() where stops.last.map({ x - $0 > step }) ?? true {
            stops.append(x)
        }

        return items.map { item in
            let level = stops.lastIndex { $0 <= item.frame.minX + step / 2 } ?? 0
            return ListItem(marker: item.marker, text: item.text, level: level)
        }
    }
}
