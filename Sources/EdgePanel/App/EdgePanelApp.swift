import AppKit
import SwiftUI

@main
struct EdgePanelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Edge Panel", systemImage: "hand.draw") {
            SettingsView(controller: appDelegate.controller)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = EdgeController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only: no Dock icon, never steals focus from the app you're using.
        NSApp.setActivationPolicy(.accessory)
        controller.start()
    }
}
