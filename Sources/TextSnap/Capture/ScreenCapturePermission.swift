import CoreGraphics

enum ScreenCapturePermission {
    /// Returns whether captures will contain real window content. On first use this
    /// triggers the system prompt; macOS applies a new grant only after relaunching the app.
    static func ensureGranted() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        return CGRequestScreenCaptureAccess()
    }
}
