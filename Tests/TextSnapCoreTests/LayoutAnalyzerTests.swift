import Testing
@testable import TextSnapCore

struct LayoutAnalyzerTests {
    private let analyzer = LayoutAnalyzer()

    @Test func emptyInputProducesEmptyDocument() {
        #expect(analyzer.analyze([]).isEmpty)
    }

    @Test func slideBecomesHeadingAndList() throws {
        let document = analyzer.analyze(Fixtures.capacitySlide)

        #expect(document.blocks.count == 2)
        #expect(document.blocks.first == .heading(level: 1, text: "R/W Capacity Modes - On-Demand"))

        guard case .list(let items) = document.blocks.last else {
            Issue.record("Expected a list, got \(document.blocks)")
            return
        }
        #expect(items.count == 8)
        #expect(items.allSatisfy { $0.marker == .bullet && $0.level == 0 })
        #expect(items[3].text == "You're charged for reads/writes that you use in terms of RRU and WRU")
    }

    @Test func fragmentsOnTheSameRowAreMerged() {
        let document = analyzer.analyze([
            Fixtures.line("throughput for reads", x: 220, row: 0),
            Fixtures.line("• Read Request Units", x: 0, row: 0),
        ])
        #expect(document.blocks == [.list(items: [ListItem(marker: .bullet, text: "Read Request Units throughput for reads")])])
    }

    @Test func softWrappedParagraphLinesAreJoined() {
        let document = analyzer.analyze([
            Fixtures.line("This sentence is long enough to wrap", row: 0, width: 400),
            Fixtures.line("onto a second line.", row: 1, width: 190),
        ])
        #expect(document.blocks == [.paragraph(lines: ["This sentence is long enough to wrap onto a second line."])])
    }

    @Test func intentionalLineBreaksAreKept() {
        let document = analyzer.analyze([
            Fixtures.line("Dear team,", row: 0, width: 100),
            Fixtures.line("The release ships on Friday after QA.", row: 1, width: 370),
        ])
        #expect(document.blocks == [.paragraph(lines: ["Dear team,", "The release ships on Friday after QA."])])
    }

    @Test func largeGapsSplitParagraphs() {
        let document = analyzer.analyze([
            Fixtures.line("First paragraph.", row: 0),
            Fixtures.line("Second paragraph.", row: 2),
        ])
        #expect(document.blocks == [
            .paragraph(lines: ["First paragraph."]),
            .paragraph(lines: ["Second paragraph."]),
        ])
    }

    @Test func indentedBulletsAreNested() {
        let document = analyzer.analyze([
            Fixtures.line("• Parent", x: 0, row: 0),
            Fixtures.line("◦ Child", x: 40, row: 1),
            Fixtures.line("▪ Grandchild", x: 80, row: 2),
            Fixtures.line("• Sibling", x: 2, row: 3),
        ])
        #expect(document.blocks == [.list(items: [
            ListItem(marker: .bullet, text: "Parent", level: 0),
            ListItem(marker: .bullet, text: "Child", level: 1),
            ListItem(marker: .bullet, text: "Grandchild", level: 2),
            ListItem(marker: .bullet, text: "Sibling", level: 0),
        ])])
    }

    @Test func secondaryHeadingIsDetected() {
        let document = analyzer.analyze([
            Fixtures.line("Section", row: 0, height: 28),
            Fixtures.line("Body one", row: 1),
            Fixtures.line("Body two", row: 2),
        ])
        #expect(document.blocks.first == .heading(level: 2, text: "Section"))
    }
}
