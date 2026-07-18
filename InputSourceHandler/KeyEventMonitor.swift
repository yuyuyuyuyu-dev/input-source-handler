//
//  KeyEventMonitor.swift
//  InputSourceHandler
//

import Foundation
import Observation

/// Watches the accessibility permission and starts the key event tap once the app is trusted.
@Observable
final class KeyEventMonitor {
    private(set) var isTrusted = false

    private let permission: any AccessibilityPermission
    private let eventTap: any KeyEventTap
    @ObservationIgnored private var isTapActive = false
    @ObservationIgnored private var pollTimer: Timer?

    init(
        permission: any AccessibilityPermission = SystemAccessibilityPermission(),
        eventTap: any KeyEventTap = CGKeyEventTap()
    ) {
        self.permission = permission
        self.eventTap = eventTap

        refreshTrust(promptIfNeeded: true)

        // If accessibility permission is not granted, check periodically until it is
        if !isTrusted {
            pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.refreshTrust()
            }
        }
    }

    /// Re-reads the permission state and starts the event tap on the transition to trusted.
    /// Keeps polling until the tap has actually started, so a failed start is retried.
    func refreshTrust(promptIfNeeded: Bool = false) {
        let trusted = permission.isTrusted(promptIfNeeded: promptIfNeeded)
        if isTrusted != trusted {
            isTrusted = trusted
        }

        guard trusted, !isTapActive else { return }
        isTapActive = eventTap.start()
        if isTapActive {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }
}
