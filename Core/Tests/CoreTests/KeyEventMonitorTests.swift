//
//  KeyEventMonitorTests.swift
//  CoreTests
//

@testable import Core
import Testing

struct KeyEventMonitorTests {
    @Test
    func shouldStartTapWhenTrustedAtLaunch() {
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()

        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        #expect(monitor.isTrusted)
        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldStayIdleWhileUntrusted() {
        let permission = AccessibilityPermissionStub()
        let tap = KeyEventTapSpy()

        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        #expect(!monitor.isTrusted)
        #expect(tap.startCallCount == 0)
    }

    @Test
    func shouldPromptOnlyAtLaunch() {
        let permission = AccessibilityPermissionStub()
        let monitor = KeyEventMonitor(permission: permission, eventTap: KeyEventTapSpy())

        monitor.refreshTrust()

        #expect(permission.promptRequests == [true, false])
    }

    @Test
    func shouldStartTapOncePermissionGranted() {
        let permission = AccessibilityPermissionStub()
        let tap = KeyEventTapSpy()
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        permission.isTrustedValue = true
        monitor.refreshTrust()

        #expect(monitor.isTrusted)
        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldStartTapOnlyOnce() {
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        monitor.refreshTrust()
        monitor.refreshTrust()

        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldRetryFailedTapStart() {
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()
        tap.startResult = false
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        tap.startResult = true
        monitor.refreshTrust()

        #expect(tap.startCallCount == 2)
    }

    @Test
    func shouldReflectRevokedPermission() {
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let monitor = KeyEventMonitor(permission: permission, eventTap: KeyEventTapSpy())

        permission.isTrustedValue = false
        monitor.refreshTrust()

        #expect(!monitor.isTrusted)
    }
}
