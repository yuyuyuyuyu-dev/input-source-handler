//
//  KeyEventMonitorTests.swift
//  CoreTests
//

@testable import Core
import Testing

struct KeyEventMonitorTests {
    @Test
    func shouldStartTapWhenTrustedAtLaunch() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()

        // Act
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        // Assert
        #expect(monitor.isTrusted)
        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldStayIdleWhileUntrusted() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        let tap = KeyEventTapSpy()

        // Act
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        // Assert
        #expect(!monitor.isTrusted)
        #expect(tap.startCallCount == 0)
    }

    @Test
    func shouldPromptOnlyAtLaunch() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        let monitor = KeyEventMonitor(permission: permission, eventTap: KeyEventTapSpy())

        // Act
        monitor.refreshTrust()

        // Assert
        #expect(permission.promptRequests == [true, false])
    }

    @Test
    func shouldStartTapOncePermissionGranted() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        let tap = KeyEventTapSpy()
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        // Act
        permission.isTrustedValue = true
        monitor.refreshTrust()

        // Assert
        #expect(monitor.isTrusted)
        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldStartTapOnlyOnce() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        // Act
        monitor.refreshTrust()
        monitor.refreshTrust()

        // Assert
        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldRetryFailedTapStart() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()
        tap.startResult = false
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        // Act
        tap.startResult = true
        monitor.refreshTrust()

        // Assert
        #expect(tap.startCallCount == 2)
    }

    @Test
    func shouldReflectRevokedPermission() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let monitor = KeyEventMonitor(permission: permission, eventTap: KeyEventTapSpy())

        // Act
        permission.isTrustedValue = false
        monitor.refreshTrust()

        // Assert
        #expect(!monitor.isTrusted)
    }
}
