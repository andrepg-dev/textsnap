import AppKit
import OSLog

/// Composition root: builds the object graph once and wires the pieces together.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private let loginItem = LoginItemController()
    private var coordinator: CaptureCoordinator?
    private var statusItem: StatusItemController?
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coordinator = CaptureCoordinator(
            capturer: InteractiveScreenshotCapturer(),
            recognizer: VisionTextRecognizer(),
            pasteboard: PasteboardWriter(),
            preferences: preferences
        )
        let statusItem = StatusItemController(
            preferences: preferences,
            loginItem: loginItem,
            onCapture: { [weak coordinator] in coordinator?.start() }
        )
        coordinator.onOutcome = { [weak statusItem] outcome in statusItem?.show(outcome) }

        self.coordinator = coordinator
        self.statusItem = statusItem
        registerHotKey(for: coordinator)
        enableLaunchAtLoginOnFirstRun()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKey?.unregister()
    }

    private func registerHotKey(for coordinator: CaptureCoordinator) {
        do {
            hotKey = try GlobalHotKey(.commandShift2) { [weak coordinator] in coordinator?.start() }
        } catch {
            Log.app.error("Hotkey registration failed: \(error.localizedDescription, privacy: .public)")
            statusItem?.markHotKeyUnavailable()
        }
    }

    private func enableLaunchAtLoginOnFirstRun() {
        guard !preferences.hasConfiguredLoginItem else { return }
        preferences.hasConfiguredLoginItem = true
        do {
            try loginItem.setEnabled(true)
        } catch {
            Log.app.error("Launch at login failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
