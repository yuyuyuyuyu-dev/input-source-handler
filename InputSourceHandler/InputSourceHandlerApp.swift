//
//  InputSourceHandlerApp.swift
//  InputSourceHandler
//

import SwiftUI

@main
struct InputSourceHandlerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var monitor = KeyEventMonitor()

    var body: some Scene {
        MenuBarExtra("InputSourceHandler", systemImage: "keyboard") {
            ContentView()
                .environmentObject(monitor)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as an accessory app without a Dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}
