//
//  LiveAdapters.swift
//  LiveAdapters
//

import ApplicationServices
import Cocoa
import Core
import ServiceManagement

// Real implementations of the Core seams. This is the only target that talks
// to the operating system; keep every adapter thin enough to verify by reading.

public struct SystemAccessibilityPermission: AccessibilityPermission {
    public init() {}

    public func isTrusted(promptIfNeeded: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: promptIfNeeded]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}

public struct HIDVirtualKeyPoster: VirtualKeyPoster {
    public init() {}

    public func post(_ keyCode: KeyCode) {
        let virtualKey = CGKeyCode(keyCode.rawValue)
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false)

        // Clear modifier flags so that physical modifiers (Control, Shift) don't leak into virtual events
        keyDown?.flags = CGEventFlags()
        keyUp?.flags = CGEventFlags()

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

public final class CGKeyEventTap: KeyEventTap {
    private var onKeyEvent: ((KeyEventPhase, KeyCode, KeyModifiers) -> Bool)?
    private var tapPort: CFMachPort?

    public init() {}

    @discardableResult
    public func start(onKeyEvent: @escaping (KeyEventPhase, KeyCode, KeyModifiers) -> Bool) -> Bool {
        guard tapPort == nil else { return true }
        self.onKeyEvent = onKeyEvent

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

    /// Translates the CGEvent into Core's own types and asks the handler whether to swallow it.
    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let swallow = onKeyEvent?(
            phase(of: type),
            KeyCode(event.getIntegerValueField(.keyboardEventKeycode)),
            modifiers(from: event.flags)
        ) ?? false
        return swallow ? nil : Unmanaged.passUnretained(event)
    }
}

private nonisolated func keyEventTapCallback(
    proxy _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<CGKeyEventTap>.fromOpaque(refcon).takeUnretainedValue()
    // The run loop source is installed on the main run loop, so this fires on the main actor.
    return MainActor.assumeIsolated { tap.handle(type: type, event: event) }
}

private func phase(of type: CGEventType) -> KeyEventPhase {
    switch type {
    case .keyDown:
        .keyDown
    case .keyUp:
        .keyUp
    default:
        .other
    }
}

private func modifiers(from flags: CGEventFlags) -> KeyModifiers {
    var modifiers: KeyModifiers = []
    if flags.contains(.maskControl) {
        modifiers.insert(.control)
    }
    if flags.contains(.maskShift) {
        modifiers.insert(.shift)
    }
    if flags.contains(.maskCommand) {
        modifiers.insert(.command)
    }
    if flags.contains(.maskAlternate) {
        modifiers.insert(.option)
    }
    if flags.contains(.maskAlphaShift) {
        modifiers.insert(.capsLock)
    }
    return modifiers
}

public struct MainAppLoginItem: LoginItemService {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

public struct WorkspaceSettingsOpener: SettingsOpener {
    public init() {}

    public func openAccessibilityPane() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

public struct SharedApplicationTerminator: AppTerminator {
    public init() {}

    public func terminate() {
        NSApplication.shared.terminate(nil)
    }
}
