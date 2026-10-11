import Testing
@testable import TextSnapCore

struct ListMarkerParserTests {
    @Test(arguments: ["• item", "•item", "- item", "* item", "– item", "◦ item", "▪ item"])
    func detectsBullets(_ text: String) {
        let parsed = ListMarkerParser.parse(text)
        #expect(parsed?.marker == .bullet)
        #expect(parsed?.content == "item")
    }

    @Test(arguments: [("1. item", "1."), ("12) item", "12)"), ("a) item", "a)"), ("b. item", "b."), ("C) item", "C)")])
    func detectsOrderedMarkers(_ text: String, _ marker: String) {
        let parsed = ListMarkerParser.parse(text)
        #expect(parsed?.marker == .ordered(marker))
        #expect(parsed?.content == "item")
    }

    @Test(arguments: ["2.5x more expensive", "-5 degrees", "J. Smith wrote", "2026 was a year", "1234. too long", "•", "plain text"])
    func ignoresNonMarkers(_ text: String) {
        #expect(ListMarkerParser.parse(text) == nil)
    }
}
