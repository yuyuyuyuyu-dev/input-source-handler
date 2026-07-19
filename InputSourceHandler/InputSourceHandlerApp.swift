//
//  InputSourceHandlerApp.swift
//  InputSourceHandler
//

import SwiftUI

@main
struct InputSourceHandlerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var monitor: KeyEventMonitor
    @State private var launchAtLogin: LaunchAtLoginSetting

    init() {
        // Unit tests launch this app as their test host. Compose an inert object
        // graph in that case, so no permission prompt or event tap ever fires
        // as a side effect of running tests.
        if ProcessInfo.processInfo.isRunningTests {
            _monitor = State(initialValue: KeyEventMonitor(
                permission: InertAccessibilityPermission(),
                eventTap: InertKeyEventTap()
            ))
            _launchAtLogin = State(initialValue: LaunchAtLoginSetting(service: InertLoginItem()))
        } else {
            _monitor = State(initialValue: KeyEventMonitor())
            _launchAtLogin = State(initialValue: LaunchAtLoginSetting())
        }
    }

    var body: some Scene {
        MenuBarExtra("InputSourceHandler", systemImage: "keyboard") {
            ContentView(monitor: monitor, launchAtLogin: launchAtLogin)
        }
        .menuBarExtraStyle(.window)
    }
}

extension ProcessInfo {
    /// True when the process was launched to host unit tests.
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
            || environment["XCTestBundlePath"] != nil
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        // Run as an accessory app without a Dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}
