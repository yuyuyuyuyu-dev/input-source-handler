//
//  KeyEventMonitorTests.swift
//  InputSourceHandlerTests
//

@testable import InputSourceHandler
import Testing

struct KeyEventMonitorTests {
    @Test("起動時に権限があれば、信頼状態になりイベントタップが開始される")
    func startsTapWhenTrustedAtLaunch() {
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()

        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        #expect(monitor.isTrusted)
        #expect(tap.startCallCount == 1)
    }

    @Test("権限が無い間は信頼状態にならず、タップも開始しない")
    func staysIdleWhileUntrusted() {
        let permission = AccessibilityPermissionStub()
        let tap = KeyEventTapSpy()

        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        #expect(!monitor.isTrusted)
        #expect(tap.startCallCount == 0)
    }

    @Test("権限プロンプトを要求するのは起動時のチェックだけ")
    func promptsOnlyAtLaunch() {
        let permission = AccessibilityPermissionStub()
        let monitor = KeyEventMonitor(permission: permission, eventTap: KeyEventTapSpy())

        monitor.refreshTrust()

        #expect(permission.promptRequests == [true, false])
    }

    @Test("権限が後から許可されたら、次のチェックでタップが開始される")
    func startsTapOncePermissionGranted() {
        let permission = AccessibilityPermissionStub()
        let tap = KeyEventTapSpy()
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        permission.isTrustedValue = true
        monitor.refreshTrust()

        #expect(monitor.isTrusted)
        #expect(tap.startCallCount == 1)
    }

    @Test("タップの開始は一度だけで、以降のチェックでは繰り返さない")
    func startsTapOnlyOnce() {
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        monitor.refreshTrust()
        monitor.refreshTrust()

        #expect(tap.startCallCount == 1)
    }

    @Test("タップの開始に失敗したら、次のチェックで再試行する")
    func retriesFailedTapStart() {
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapSpy()
        tap.startResult = false
        let monitor = KeyEventMonitor(permission: permission, eventTap: tap)

        tap.startResult = true
        monitor.refreshTrust()

        #expect(tap.startCallCount == 2)
    }

    @Test("権限を剥奪されたら信頼状態は false に戻る")
    func reflectsRevokedPermission() {
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let monitor = KeyEventMonitor(permission: permission, eventTap: KeyEventTapSpy())

        permission.isTrustedValue = false
        monitor.refreshTrust()

        #expect(!monitor.isTrusted)
    }
}
