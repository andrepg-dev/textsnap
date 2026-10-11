import Testing
@testable import TextSnapCore

struct TextJoinerTests {
    @Test func joinsWithSpace() {
        #expect(TextJoiner.join("in terms of RRU and", "WRU") == "in terms of RRU and WRU")
    }

    @Test func removesHyphenationOfSplitWords() {
        #expect(TextJoiner.join("infor-", "mation") == "information")
    }

    @Test func keepsHyphenBeforeCapitalOrNumber() {
        #expect(TextJoiner.join("On-", "Demand") == "On- Demand")
        #expect(TextJoiner.join("COVID-", "19 cases") == "COVID- 19 cases")
    }

    @Test func handlesEmptySides() {
        #expect(TextJoiner.join("", "a") == "a")
        #expect(TextJoiner.join("a", "") == "a")
    }
}
