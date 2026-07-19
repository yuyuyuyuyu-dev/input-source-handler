//
//  InputSourceHandlerApp.swift
//  InputSourceHandler
//

import Core
import LiveAdapters
import SwiftUI

@main
struct InputSourceHandlerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var monitor = KeyEventMonitor(
        permission: SystemAccessibilityPermission(),
        eventTap: CGKeyEventTap()
    )
    @State private var launchAtLogin = LaunchAtLoginSetting(service: MainAppLoginItem())

    var body: some Scene {
        MenuBarExtra("InputSourceHandler", systemImage: "keyboard") {
            ContentView(monitor: monitor, launchAtLogin: launchAtLogin)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        // Run as an accessory app without a Dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}
