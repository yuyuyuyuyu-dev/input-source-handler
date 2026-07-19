//
//  Boundaries.swift
//  Core
//

import CoreGraphics
import Foundation

// MARK: - Seams

// The protocols below are the only paths through which the logic touches the OS.
// Real implementations live in the LiveAdapters target, which Core cannot import,
// so code in this target has no way to reach the real system even by accident.

/// Reads whether this process is trusted for accessibility.
public protocol AccessibilityPermission {
    func isTrusted(promptIfNeeded: Bool) -> Bool
}

/// Posts a virtual key press (down + up) to the system.
public protocol VirtualKeyPoster {
    func post(_ keyCode: CGKeyCode)
}

/// Intercepts keyboard events once started.
/// Starting an already running tap is a no-op that reports success.
public protocol KeyEventTap {
    @discardableResult
    func start() -> Bool
}

/// Manages the "launch at login" registration of the app.
public protocol LoginItemService {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

/// Opens panes of the System Settings app.
public protocol SettingsOpener {
    func openAccessibilityPane()
}

// MARK: - Inert implementations

// Fixed, side-effect-free stand-ins for previews and other contexts that need
// a composed object graph without touching the real system.

public struct InertAccessibilityPermission: AccessibilityPermission {
    public init() {}

    public func isTrusted(promptIfNeeded _: Bool) -> Bool {
        false
    }
}

public struct InertKeyEventTap: KeyEventTap {
    public init() {}

    @discardableResult
    public func start() -> Bool {
        false
    }
}

public struct InertLoginItem: LoginItemService {
    public init() {}

    public var isEnabled: Bool {
        false
    }

    public func setEnabled(_: Bool) throws {}
}
