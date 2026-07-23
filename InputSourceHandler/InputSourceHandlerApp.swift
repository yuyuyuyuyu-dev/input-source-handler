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
    @State private var viewModel = ContentViewModel(
        permission: SystemAccessibilityPermission(),
        eventTap: CGKeyEventTap(),
        poster: HIDVirtualKeyPoster(),
        loginItem: MainAppLoginItem(),
        settingsOpener: WorkspaceSettingsOpener()
    )

    var body: some Scene {
        MenuBarExtra("InputSourceHandler", systemImage: "keyboard") {
            ContentView(viewModel: viewModel)
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
