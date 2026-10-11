import CoreGraphics
import OSLog
import TextSnapCore

/// Runs the capture → OCR → format → copy pipeline, one capture at a time.
@MainActor
final class CaptureCoordinator {
    enum Outcome {
        case copied
        case noTextFound
        case cancelled
        case permissionRequired
        case failed(any Error)
    }

    var onOutcome: ((Outcome) -> Void)?

    private let capturer: any ScreenCapturing
    private let recognizer: any TextRecognizing
    private let pasteboard: PasteboardWriter
    private let preferences: Preferences
    private let formatter = TextFormatter()
    private var currentTask: Task<Void, Never>?

    init(
        capturer: any ScreenCapturing,
        recognizer: any TextRecognizing,
        pasteboard: PasteboardWriter,
        preferences: Preferences
    ) {
        self.capturer = capturer
        self.recognizer = recognizer
        self.pasteboard = pasteboard
        self.preferences = preferences
    }

    /// Ignored while a capture is already in progress, so repeated hotkey presses are harmless.
    func start() {
        guard currentTask == nil else { return }
        currentTask = Task {
            let outcome = await run()
            currentTask = nil
            onOutcome?(outcome)
        }
    }

    private func run() async -> Outcome {
        guard ScreenCapturePermission.ensureGranted() else { return .permissionRequired }

        do {
            guard let image = try await capturer.captureInteractively() else { return .cancelled }
            let lines = try await recognizer.recognizeLines(in: image)
            let format = preferences.outputFormat
            let text = formatter.format(lines, as: format)
            guard !text.isEmpty else { return .noTextFound }

            pasteboard.write(text, as: format)
            return .copied
        } catch {
            Log.capture.error("Capture failed: \(error.localizedDescription, privacy: .public)")
            return .failed(error)
        }
    }
}
