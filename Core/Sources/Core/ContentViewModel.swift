//
//  ContentViewModel.swift
//  Core
//

import Foundation
import Observation

/// A command the menu bar icon's context menu offers.
public enum ContextMenuCommand: Sendable {
    case quit

    public var title: String {
        switch self {
        case .quit:
            "終了"
        }
    }
}

/// Backs `ContentView` and coordinates the whole app: it watches the accessibility
/// permission, remaps intercepted key events, and mirrors the launch-at-login setting.
///
/// Every dependency it takes is an external-OS boundary. All the decision logic
/// (remapping rules, the trust-then-intercept lifecycle, launch-at-login revert)
/// is real and lives inside, so a test that fakes only these six boundaries exercises
/// the genuine behaviour.
@Observable
public final class ContentViewModel {
    public private(set) var isTrusted = false

    /// The commands the menu bar icon's context menu lists, in display order.
    public let menuBarContextMenu: [ContextMenuCommand] = [.quit]

    public var isLaunchAtLoginEnabled: Bool {
        didSet { applyLaunchAtLogin(from: oldValue) }
    }

    private let permission: any AccessibilityPermission
    private let eventTap: any KeyEventTap
    private let poster: any VirtualKeyPoster
    private let loginItem: any LoginItemService
    private let settingsOpener: any SettingsOpener
    private let terminator: any AppTerminator

    @ObservationIgnored private var remapper = ShortcutRemapper()
    @ObservationIgnored private var isIntercepting = false
    @ObservationIgnored private var isRevertingLaunchAtLogin = false
    @ObservationIgnored private var pollTimer: Timer?

    public init(
        permission: any AccessibilityPermission,
        eventTap: any KeyEventTap,
        poster: any VirtualKeyPoster,
        loginItem: any LoginItemService,
        settingsOpener: any SettingsOpener,
        terminator: any AppTerminator
    ) {
        self.permission = permission
        self.eventTap = eventTap
        self.poster = poster
        self.loginItem = loginItem
        self.settingsOpener = settingsOpener
        self.terminator = terminator
        isLaunchAtLoginEnabled = loginItem.isEnabled

        refreshTrust(promptIfNeeded: true)

        // If accessibility permission is not granted, check periodically until it is
        if !isTrusted {
            pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.refreshTrust()
            }
        }
    }

    /// Re-reads the permission state and starts intercepting on the transition to trusted.
    /// Keeps polling until interception has actually started, so a failed start is retried.
    func refreshTrust(promptIfNeeded: Bool = false) {
        let trusted = permission.isTrusted(promptIfNeeded: promptIfNeeded)
        if isTrusted != trusted {
            isTrusted = trusted
        }

        guard trusted, !isIntercepting else { return }
        isIntercepting = eventTap.start { [weak self] phase, keyCode, modifiers in
            self?.handleKeyEvent(phase: phase, keyCode: keyCode, modifiers: modifiers) ?? false
        }
        if isIntercepting {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    /// Applies the remapping rules to one intercepted event and returns whether the
    /// original event should be swallowed. This is the exact entry point the OS tap calls.
    @discardableResult
    func handleKeyEvent(phase: KeyEventPhase, keyCode: KeyCode, modifiers: KeyModifiers) -> Bool {
        switch remapper.handle(phase: phase, keyCode: keyCode, modifiers: modifiers) {
        case .passThrough:
            return false
        case .discard:
            return true
        case let .discardAndPost(replacement):
            poster.post(replacement)
            return true
        }
    }

    public func openAccessibilitySettings() {
        settingsOpener.openAccessibilityPane()
    }

    public func perform(_ command: ContextMenuCommand) {
        switch command {
        case .quit:
            terminator.terminate()
        }
    }

    private func applyLaunchAtLogin(from oldValue: Bool) {
        guard !isRevertingLaunchAtLogin, isLaunchAtLoginEnabled != oldValue else { return }
        do {
            try loginItem.setEnabled(isLaunchAtLoginEnabled)
        } catch {
            print("Failed to change login item: \(error)")
            isRevertingLaunchAtLogin = true
            isLaunchAtLoginEnabled = loginItem.isEnabled
            isRevertingLaunchAtLogin = false
        }
    }
}
