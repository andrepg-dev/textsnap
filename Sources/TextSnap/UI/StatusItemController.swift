import AppKit
import TextSnapCore

/// Menu bar icon and menu. The menu is rebuilt only when opened, so state such as
/// the login item (which the user can change in System Settings) is always fresh.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private enum Symbol {
        static let idle = "text.viewfinder"
        static let success = "checkmark.circle"
        static let warning = "exclamationmark.triangle"
    }

    private static let feedbackDuration: Duration = .seconds(1.2)

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let preferences: Preferences
    private let loginItem: LoginItemController
    private let onCapture: () -> Void
    private var hotKeyAvailable = true
    private var feedbackTask: Task<Void, Never>?

    init(preferences: Preferences, loginItem: LoginItemController, onCapture: @escaping () -> Void) {
        self.preferences = preferences
        self.loginItem = loginItem
        self.onCapture = onCapture
        super.init()

        setIcon(Symbol.idle)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func markHotKeyUnavailable() {
        hotKeyAvailable = false
    }

    func show(_ outcome: CaptureCoordinator.Outcome) {
        switch outcome {
        case .copied:
            flash(Symbol.success, sound: "Tink")
        case .noTextFound, .failed:
            flash(Symbol.warning, sound: "Basso")
        case .permissionRequired:
            showPermissionAlert()
        case .cancelled:
            break
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

    private func setIcon(_ symbolName: String) {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "TextSnap")
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    private func flash(_ symbolName: String, sound: NSSound.Name) {
        NSSound(named: sound)?.play()
        setIcon(symbolName)
        feedbackTask?.cancel()
        feedbackTask = Task {
            try? await Task.sleep(for: Self.feedbackDuration)
            guard !Task.isCancelled else { return }
            setIcon(Symbol.idle)
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
