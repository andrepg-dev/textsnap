import AppKit
import TextSnapCore

/// Menu bar icon and menu. The menu is rebuilt only when opened, so state such as
/// the login item (which the user can change in System Settings) is always fresh.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    /// What the menu bar button shows. Every change goes through `display(_:)`
    /// so the spinner and the symbol never appear at the same time.
    private enum Indicator {
        case idle
        case processing
        case success
        case warning

        var symbolName: String? {
            switch self {
            case .idle: "text.viewfinder"
            case .processing: nil
            case .success: "checkmark.circle"
            case .warning: "exclamationmark.triangle"
            }
        }
    }

    private static let feedbackDuration: Duration = .seconds(1.2)

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let preferences: Preferences
    private let loginItem: LoginItemController
    private let onCapture: () -> Void
    private var hotKeyAvailable = true
    private var feedbackTask: Task<Void, Never>?
    private let spinner = NSProgressIndicator()

    init(preferences: Preferences, loginItem: LoginItemController, onCapture: @escaping () -> Void) {
        self.preferences = preferences
        self.loginItem = loginItem
        self.onCapture = onCapture
        super.init()

        installSpinner()
        display(.idle)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func markHotKeyUnavailable() {
        hotKeyAvailable = false
    }

    func show(_ event: CaptureCoordinator.Event) {
        switch event {
        case .processing:
            feedbackTask?.cancel()
            display(.processing)
        case .finished(let outcome):
            show(outcome)
        }
    }

    private func show(_ outcome: CaptureCoordinator.Outcome) {
        switch outcome {
        case .copied:
            flash(.success, sound: FeedbackSound.copied)
        case .noTextFound, .failed:
            flash(.warning, sound: FeedbackSound.failed)
        case .permissionRequired:
            display(.idle)
            showPermissionAlert()
        case .cancelled:
            display(.idle)
        }
    }

    // MARK: NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let capture = item("Capturar texto", action: #selector(captureSelected), key: "2")
        capture.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(capture)
        if !hotKeyAvailable {
            menu.addItem(disabledItem("⌘⇧2 está en uso por otra app"))
        }
        menu.addItem(.separator())

        menu.addItem(disabledItem("Copiar como"))
        for format in OutputFormat.allCases {
            let formatItem = item(format.title, action: #selector(formatSelected(_:)))
            formatItem.representedObject = format.rawValue
            formatItem.state = preferences.outputFormat == format ? .on : .off
            formatItem.indentationLevel = 1
            menu.addItem(formatItem)
        }
        menu.addItem(.separator())

        let login = item("Abrir al iniciar sesión", action: #selector(loginItemToggled))
        login.state = loginItem.isEnabled ? .on : (loginItem.requiresApproval ? .mixed : .off)
        menu.addItem(login)
        menu.addItem(.separator())

        menu.addItem(item("Salir de TextSnap", action: #selector(quitSelected), key: "q"))
    }

    // MARK: Actions

    @objc private func captureSelected() {
        onCapture()
    }

    @objc private func formatSelected(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let format = OutputFormat(rawValue: raw) else { return }
        preferences.outputFormat = format
    }

    @objc private func loginItemToggled() {
        if loginItem.requiresApproval {
            loginItem.openSystemSettings()
            return
        }
        do {
            try loginItem.setEnabled(!loginItem.isEnabled)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    @objc private func quitSelected() {
        NSApp.terminate(nil)
    }

    // MARK: Helpers

    private func item(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    /// A small native spinner centered in the button. It is hidden and does no
    /// drawing work while stopped, so it costs nothing outside of processing.
    private func installSpinner() {
        guard let button = statusItem.button else { return }
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.setAccessibilityLabel("Procesando captura")
        spinner.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
    }

    private func display(_ indicator: Indicator) {
        if let symbolName = indicator.symbolName {
            spinner.stopAnimation(nil)
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "TextSnap")
            image?.isTemplate = true
            statusItem.button?.image = image
        } else {
            statusItem.button?.image = nil
            spinner.startAnimation(nil)
        }
    }

    private func flash(_ indicator: Indicator, sound: NSSound?) {
        sound?.play()
        display(indicator)
        feedbackTask?.cancel()
        feedbackTask = Task {
            try? await Task.sleep(for: Self.feedbackDuration)
            guard !Task.isCancelled else { return }
            display(.idle)
        }
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "TextSnap necesita permiso de Grabación de pantalla"
        alert.informativeText = "Actívalo en Ajustes del Sistema › Privacidad y seguridad › Grabación de pantalla y del audio del sistema, luego vuelve a abrir TextSnap."
        alert.addButton(withTitle: "Abrir Ajustes")
        alert.addButton(withTitle: "Cancelar")
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}

private extension OutputFormat {
    var title: String {
        switch self {
        case .markdown: "Markdown"
        case .plainText: "Texto plano"
        }
    }
}
