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

    var body: some Scene {
        // The menu bar item is an AppKit status item owned by the delegate, because
        // MenuBarExtra cannot show a context menu on a secondary click. This scene
        // exists only because an App needs one; an accessory app never opens it.
        Settings {}
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = ContentViewModel(
        permission: SystemAccessibilityPermission(),
        eventTap: CGKeyEventTap(),
        poster: HIDVirtualKeyPoster(),
        loginItem: MainAppLoginItem(),
        settingsOpener: WorkspaceSettingsOpener(),
        terminator: SharedApplicationTerminator()
    )
    private let panel = NSPopover()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_: Notification) {
        // Run as an accessory app without a Dock icon
        NSApp.setActivationPolicy(.accessory)

        panel.behavior = .transient
        panel.contentViewController = NSHostingController(rootView: ContentView(viewModel: viewModel))

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "InputSourceHandler")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        self.statusItem = statusItem
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        // Control-clicking arrives as a left click, and means the same as a right click
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func showContextMenu() {
        guard let statusItem else { return }

        let menu = NSMenu()
        for command in viewModel.menuBarContextMenu {
            let item = NSMenuItem(title: command.title, action: #selector(runContextMenuCommand), keyEquivalent: "")
            item.target = self
            item.representedObject = command
            menu.addItem(item)
        }

        // Handing the menu to the status item lets the system draw it in the menu bar's
        // own material and highlight the icon. Popping it up from the button instead
        // inherits the menu bar's vibrant appearance, which has nothing to blend with
        // once the menu is its own window, and renders as a flat dark background.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func runContextMenuCommand(_ sender: NSMenuItem) {
        guard let command = sender.representedObject as? ContextMenuCommand else { return }
        viewModel.perform(command)
    }

    private func togglePanel() {
        guard let button = statusItem?.button else { return }

        if panel.isShown {
            panel.performClose(nil)
        } else {
            panel.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // An accessory app is not active when its status item is clicked,
            // so the panel would otherwise open behind the frontmost window
            NSApp.activate()
        }
    }
}
