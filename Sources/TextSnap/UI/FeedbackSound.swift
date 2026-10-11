import AppKit

/// Sounds played after a capture. Each one is loaded on first use and then reused.
@MainActor
enum FeedbackSound {
    /// The shutter macOS plays for ⌘⇧4, so a copy sounds like the gesture it mirrors.
    /// It is not a public asset; if a macOS update moves it, fall back to a stock sound.
    private static let shutterURL = URL(
        filePath: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif"
    )

    static let copied = NSSound(contentsOf: shutterURL, byReference: true) ?? NSSound(named: "Pop")
    static let failed = NSSound(named: "Basso")
}
