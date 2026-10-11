import ServiceManagement

/// "Open at Login" via `SMAppService`; shows up in System Settings › General › Login Items.
@MainActor
struct LoginItemController {
    private var service: SMAppService { .mainApp }

    var isEnabled: Bool { service.status == .enabled }
    var requiresApproval: Bool { service.status == .requiresApproval }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
