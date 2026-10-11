import Testing
@testable import TextSnapCore

struct RendererTests {
    private let document = Document(blocks: [
        .heading(level: 1, text: "Title"),
        .paragraph(lines: ["Intro line.", "Second line."]),
        .list(items: [
            ListItem(marker: .bullet, text: "One"),
            ListItem(marker: .ordered("1."), text: "Nested", level: 1),
            ListItem(marker: .ordered("a)"), text: "Lettered", level: 1),
        ]),
    ])

    @Test func markdown() {
        #expect(MarkdownRenderer().render(document) == """
        # Title

        Intro line.
        Second line.

        - One
            1. Nested
            - a) Lettered
        """)
    }

    @Test func plainText() {
        #expect(PlainTextRenderer().render(document) == """
        Title

        Intro line.
        Second line.

        • One
          1. Nested
          a) Lettered
        """)
    }

    @Test func formatsSlideAsMarkdownEndToEnd() {
        let markdown = TextFormatter().format(Fixtures.capacitySlide, as: .markdown)
        #expect(markdown == """
        # R/W Capacity Modes - On-Demand

        - Read/writes automatically scale up/down with your workloads
        - No capacity planning needed (WCU / RCU)
        - Unlimited WCU & RCU, no throttle, more expensive
        - You're charged for reads/writes that you use in terms of RRU and WRU
        - Read Request Units (RRU) - throughput for reads (same as RCU)
        - Write Request Units (WRU) - throughput for writes (same as WCU)
        - 2.5x more expensive than provisioned capacity (use with care)
        - Use cases: unknown workloads, unpredictable application traffic, ...
        """)
    }
}
