//
//  ContentViewModelPermissionTests.swift
//  CoreTests
//

@testable import Core
import Testing

struct ContentViewModelPermissionTests {
    @Test
    func shouldStartInterceptingWhenTrustedAtLaunch() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapFake()

        // Act
        let viewModel = makeViewModel(permission: permission, tap: tap)

        // Assert
        #expect(viewModel.isTrusted)
        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldStayIdleWhileUntrusted() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        let tap = KeyEventTapFake()

        // Act
        let viewModel = makeViewModel(permission: permission, tap: tap)

        // Assert
        #expect(!viewModel.isTrusted)
        #expect(tap.startCallCount == 0)
    }

    @Test
    func shouldPromptOnlyAtLaunch() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        let viewModel = makeViewModel(permission: permission)

        // Act
        viewModel.refreshTrust()

        // Assert
        #expect(permission.promptRequests == [true, false])
    }

    @Test
    func shouldStartInterceptingOncePermissionGranted() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        let tap = KeyEventTapFake()
        let viewModel = makeViewModel(permission: permission, tap: tap)

        // Act
        permission.isTrustedValue = true
        viewModel.refreshTrust()

        // Assert
        #expect(viewModel.isTrusted)
        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldStartInterceptingOnlyOnce() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapFake()
        let viewModel = makeViewModel(permission: permission, tap: tap)

        // Act
        viewModel.refreshTrust()
        viewModel.refreshTrust()

        // Assert
        #expect(tap.startCallCount == 1)
    }

    @Test
    func shouldRetryFailedInterceptionStart() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapFake()
        tap.startResult = false
        let viewModel = makeViewModel(permission: permission, tap: tap)

        // Act
        tap.startResult = true
        viewModel.refreshTrust()

        // Assert
        #expect(tap.startCallCount == 2)
    }

    @Test
    func shouldReflectRevokedPermission() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let viewModel = makeViewModel(permission: permission)

        // Act
        permission.isTrustedValue = false
        viewModel.refreshTrust()

        // Assert
        #expect(!viewModel.isTrusted)
    }

    @Test
    func shouldOpenAccessibilityPaneWhenRequested() {
        // Arrange
        let settingsOpener = SettingsOpenerSpy()
        let viewModel = makeViewModel(settingsOpener: settingsOpener)

        // Act
        viewModel.openAccessibilitySettings()

        // Assert
        #expect(settingsOpener.openAccessibilityPaneCount == 1)
    }
}
