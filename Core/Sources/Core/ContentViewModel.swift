//
//  ContentViewModel.swift
//  Core
//

import Foundation
import Observation

/// Backs `ContentView` and coordinates the whole app: it watches the accessibility
/// permission, remaps intercepted key events, and mirrors the launch-at-login setting.
///
/// Every dependency it takes is an external-OS boundary. All the decision logic
/// (remapping rules, the trust-then-intercept lifecycle, launch-at-login revert)
/// is real and lives inside, so a test that fakes only these five boundaries exercises
/// the genuine behaviour.
@Observable
public final class ContentViewModel {
    public private(set) var isTrusted = false

    public var isLaunchAtLoginEnabled: Bool {
        didSet { applyLaunchAtLogin(from: oldValue) }
    }

    private let permission: any AccessibilityPermission
    private let eventTap: any KeyEventTap
    private let poster: any VirtualKeyPoster
    private let loginItem: any LoginItemService
    private let settingsOpener: any SettingsOpener

    @ObservationIgnored private var remapper = ShortcutRemapper()
    @ObservationIgnored private var isIntercepting = false
    @ObservationIgnored private var isRevertingLaunchAtLogin = false
    @ObservationIgnored private var pollTimer: Timer?

    public init(
        permission: any AccessibilityPermission,
        eventTap: any KeyEventTap,
        poster: any VirtualKeyPoster,
        loginItem: any LoginItemService,
        settingsOpener: any SettingsOpener
    ) {
        self.permission = permission
        self.eventTap = eventTap
        self.poster = poster
        self.loginItem = loginItem
        self.settingsOpener = settingsOpener
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
