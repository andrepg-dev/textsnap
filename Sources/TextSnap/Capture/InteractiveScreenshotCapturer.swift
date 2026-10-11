import Foundation
import ImageIO

/// Delegates selection to the system `screencapture` tool, so the experience is
/// identical to ⌘⇧4: crosshair, Space to pick a window, Esc to cancel.
struct InteractiveScreenshotCapturer: ScreenCapturing {
    enum CaptureError: LocalizedError {
        case toolFailed(status: Int32)
        case unreadableImage

        var errorDescription: String? {
            switch self {
            case .toolFailed(let status): "screencapture exited with status \(status)"
            case .unreadableImage: "The captured image could not be decoded"
            }
        }
    }

    private static let tool = URL(filePath: "/usr/sbin/screencapture")

    @concurrent
    func captureInteractively() async throws -> CGImage? {
        let file = FileManager.default.temporaryDirectory
            .appending(path: "textsnap-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: file) }

        // -i interactive, -x no shutter sound, -o no window shadow (cleaner OCR input).
        let status = try await Self.runTool(arguments: ["-i", "-x", "-o", file.path])

        // Esc leaves no file behind; that is a cancellation, not an error.
        guard FileManager.default.fileExists(atPath: file.path) else {
            if status == 0 || status == 1 { return nil }
            throw CaptureError.toolFailed(status: status)
        }
        return try Self.decode(Data(contentsOf: file))
    }

    /// Decodes eagerly. A `CGImage` from ImageIO is lazy by default and would read
    /// its pixels later — after the temporary file above has already been deleted.
    private static func decode(_ data: Data) throws -> CGImage {
        let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, options)
        else {
            throw CaptureError.unreadableImage
        }
        return image
    }

    private static func runTool(arguments: [String]) async throws -> Int32 {
        let process = Process()
        process.executableURL = tool
        process.arguments = arguments

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}
