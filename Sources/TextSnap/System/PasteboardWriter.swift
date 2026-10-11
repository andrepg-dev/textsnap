import AppKit
import TextSnapCore
import UniformTypeIdentifiers

@MainActor
struct PasteboardWriter {
    private static let markdownType = NSPasteboard.PasteboardType(UTType("net.daringfireball.markdown")?.identifier ?? "net.daringfireball.markdown")

    /// Always provides plain text; Markdown is also tagged so apps that understand it can opt in.
    func write(_ text: String, as format: OutputFormat) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        if format == .markdown {
            pasteboard.setString(text, forType: Self.markdownType)
        }
    }
}
