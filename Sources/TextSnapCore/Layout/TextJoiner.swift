/// Joins a soft-wrapped line onto the text that precedes it.
enum TextJoiner {
    static func join(_ head: String, _ tail: String) -> String {
        guard !head.isEmpty else { return tail }
        guard !tail.isEmpty else { return head }

        // "infor-" + "mation" → "information". Only when the break clearly splits a word.
        if head.hasSuffix("-"),
           head.dropLast().last?.isLetter == true,
           tail.first?.isLowercase == true {
            return head.dropLast() + tail
        }
        return head + " " + tail
    }
}
