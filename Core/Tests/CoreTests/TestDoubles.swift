//
//  TestDoubles.swift
//  CoreTests
//
//  Every fake here stands in for one external-OS boundary. Nothing else is faked:
//  the ViewModel builds its real logic (remapping, lifecycle, revert) internally.
//

@testable import Core

final class AccessibilityPermissionStub: AccessibilityPermission {
    var isTrustedValue = false
    private(set) var promptRequests: [Bool] = []

    func isTrusted(promptIfNeeded: Bool) -> Bool {
        promptRequests.append(promptIfNeeded)
        return isTrustedValue
    }
}

final class KeyEventTapFake: KeyEventTap {
    var startResult = true
    private(set) var startCallCount = 0
    private var onKeyEvent: ((KeyEventPhase, KeyCode, KeyModifiers) -> Bool)?

    @discardableResult
    func start(onKeyEvent: @escaping (KeyEventPhase, KeyCode, KeyModifiers) -> Bool) -> Bool {
        startCallCount += 1
        self.onKeyEvent = onKeyEvent
        return startResult
    }

    /// Simulates the OS delivering one intercepted key event to whoever started the tap.
    func simulate(phase: KeyEventPhase, keyCode: KeyCode, modifiers: KeyModifiers) -> Bool {
        onKeyEvent?(phase, keyCode, modifiers) ?? false
    }
}

final class VirtualKeyPosterSpy: VirtualKeyPoster {
    private(set) var postedKeys: [KeyCode] = []

    func post(_ keyCode: KeyCode) {
        postedKeys.append(keyCode)
    }
}

final class LoginItemServiceFake: LoginItemService {
    var isEnabled: Bool
    var nextError: (any Error)?
    private(set) var receivedRequests: [Bool] = []

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        receivedRequests.append(enabled)
        if let nextError {
            throw nextError
        }
        isEnabled = enabled
    }
}

final class SettingsOpenerSpy: SettingsOpener {
    private(set) var openAccessibilityPaneCount = 0

    func openAccessibilityPane() {
        openAccessibilityPaneCount += 1
    }
}

struct FakeError: Error {}
