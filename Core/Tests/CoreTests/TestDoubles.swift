//
//  TestDoubles.swift
//  CoreTests
//

@testable import Core
import CoreGraphics
import Foundation

final class AccessibilityPermissionStub: AccessibilityPermission {
    var isTrustedValue = false
    private(set) var promptRequests: [Bool] = []

    func isTrusted(promptIfNeeded: Bool) -> Bool {
        promptRequests.append(promptIfNeeded)
        return isTrustedValue
    }
}

final class KeyEventTapSpy: KeyEventTap {
    var startResult = true
    private(set) var startCallCount = 0

    @discardableResult
    func start() -> Bool {
        startCallCount += 1
        return startResult
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

struct FakeError: Error {}
