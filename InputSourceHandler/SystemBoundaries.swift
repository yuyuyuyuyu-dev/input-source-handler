//
//  SystemBoundaries.swift
//  InputSourceHandler
//

import ApplicationServices
import Cocoa
import ServiceManagement

// MARK: - Seams

// The protocols below are the only paths through which the app touches the OS.
// Tests replace them with fakes; production uses the real implementations further down.

/// Reads whether this process is trusted for accessibility.
protocol AccessibilityPermission {
    func isTrusted(promptIfNeeded: Bool) -> Bool
}

/// Posts a virtual key press (down + up) to the system.
protocol VirtualKeyPoster {
    func post(_ keyCode: CGKeyCode)
}

/// Intercepts keyboard events once started.
/// Starting an already running tap is a no-op that reports success.
protocol KeyEventTap {
    @discardableResult
    func start() -> Bool
}

/// Manages the "launch at login" registration of the app.
protocol LoginItemService {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

/// Opens panes of the System Settings app.
protocol SettingsOpener {
    func openAccessibilityPane()
}

// MARK: - Real implementations

struct SystemAccessibilityPermission: AccessibilityPermission {
    func isTrusted(promptIfNeeded: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: promptIfNeeded]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}

struct HIDVirtualKeyPoster: VirtualKeyPoster {
    func post(_ keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)

        // Clear modifier flags so that physical modifiers (Control, Shift) don't leak into virtual events
        keyDown?.flags = CGEventFlags()
        keyUp?.flags = CGEventFlags()

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

final class CGKeyEventTap: KeyEventTap {
    private var remapper = ShortcutRemapper()
    private let poster: any VirtualKeyPoster
    private var tapPort: CFMachPort?

    init(poster: any VirtualKeyPoster = HIDVirtualKeyPoster()) {
        self.poster = poster
    }

    @discardableResult
    func start() -> Bool {
        guard tapPort == nil else { return true }

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: keyEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap else {
            print("Failed to create event tap")
            return false
        }

        tapPort = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        switch remapper.handle(type: type, keyCode: keyCode, flags: event.flags) {
        case .passThrough:
            return Unmanaged.passUnretained(event)
        case .discard:
            return nil
        case let .discardAndPost(replacement):
            poster.post(replacement)
            return nil
        }
    }
}

private func keyEventTapCallback(
    proxy _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    return Unmanaged<CGKeyEventTap>.fromOpaque(refcon).takeUnretainedValue().handle(type: type, event: event)
}

struct MainAppLoginItem: LoginItemService {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

struct WorkspaceSettingsOpener: SettingsOpener {
    func openAccessibilityPane() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Inert implementations

// Used by the app while unit tests host it, and by previews, so that composing
// the object graph never prompts for permissions or touches the real system.

struct InertAccessibilityPermission: AccessibilityPermission {
    func isTrusted(promptIfNeeded _: Bool) -> Bool {
        false
    }
}

struct InertKeyEventTap: KeyEventTap {
    @discardableResult
    func start() -> Bool {
        false
    }
}

struct InertLoginItem: LoginItemService {
    var isEnabled: Bool {
        false
    }

    func setEnabled(_: Bool) throws {}
}
