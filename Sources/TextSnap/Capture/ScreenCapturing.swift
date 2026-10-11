import CoreGraphics

protocol ScreenCapturing: Sendable {
    /// Lets the user pick a region or window. Returns `nil` when the user cancels.
    func captureInteractively() async throws -> CGImage?
}
