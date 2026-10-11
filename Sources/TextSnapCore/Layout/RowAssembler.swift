import CoreGraphics

/// Merges OCR fragments that sit on the same visual row into a single line,
/// and returns rows in reading order (top to bottom).
struct RowAssembler {
    /// Minimum vertical overlap, relative to the shorter fragment, for two fragments to share a row.
    var sameRowOverlap: CGFloat = 0.5
    /// Horizontal gaps wider than this many average character widths are kept as runs of spaces.
    var wideGapInCharacters: CGFloat = 3
    var maxPreservedSpaces = 12

    func assemble(_ fragments: [TextLine]) -> [TextLine] {
        let ordered = fragments
            .filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
            .sorted { $0.frame.minY < $1.frame.minY }

        var rows: [[TextLine]] = []
        for fragment in ordered {
            if let anchor = rows.last?.first, sharesRow(anchor.frame, fragment.frame) {
                rows[rows.count - 1].append(fragment)
            } else {
                rows.append([fragment])
            }
        }
        return rows.map(merge)
    }

    private func sharesRow(_ a: CGRect, _ b: CGRect) -> Bool {
        let overlap = min(a.maxY, b.maxY) - max(a.minY, b.minY)
        return overlap >= sameRowOverlap * min(a.height, b.height)
    }

    private func merge(_ row: [TextLine]) -> TextLine {
        let fragments = row.sorted { $0.frame.minX < $1.frame.minX }
        var text = ""
        var frame = fragments[0].frame
        var previous: TextLine?

        for fragment in fragments {
            if let previous {
                text += separator(between: previous, and: fragment)
                frame = frame.union(fragment.frame)
            }
            text += fragment.text
            previous = fragment
        }
        return TextLine(text: text, frame: frame)
    }

    private func separator(between left: TextLine, and right: TextLine) -> String {
        let characterWidth = left.frame.width / CGFloat(max(left.text.count, 1))
        let gap = right.frame.minX - left.frame.maxX
        guard characterWidth > 0, gap > wideGapInCharacters * characterWidth else { return " " }
        let spaces = Int((gap / characterWidth).rounded())
        return String(repeating: " ", count: min(spaces, maxPreservedSpaces))
    }
}
