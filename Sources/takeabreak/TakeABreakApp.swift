import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = BreakTimerStore()
    private var overlayController: BreakOverlayController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.shared.log("App launched (version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?"))")
        NSApplication.shared.setActivationPolicy(.regular)
        applyAppIcon()
        NSApplication.shared.activate(ignoringOtherApps: true)
        overlayController = BreakOverlayController(store: store)
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in
                if let error {
                    AppLogger.shared.log("Notification permission error: \(error)", level: "ERROR")
                } else {
                    AppLogger.shared.log("Notification permission granted: \(granted)")
                }
            }
        }
    }

    private func applyAppIcon() {
        guard
            let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
            let icon = NSImage(contentsOf: iconURL)
        else {
            return
        }

        NSApplication.shared.applicationIconImage = icon
    }
}

@main
struct TakeABreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("TakeABreak") {
            MenuBarContentView(store: appDelegate.store)
                .frame(minWidth: 320, minHeight: 240)
        }

        MenuBarExtra("TAB", systemImage: "cup.and.saucer.fill") {
            MenuBarContentView(store: appDelegate.store)
        }
        .menuBarExtraStyle(.window)
    }
}
