//
//  ContentViewModelTests.swift
//  CoreTests
//

@testable import Core
import Testing

/// Builds the system under test. Its five parameters are exactly the app's external-OS
/// boundaries and nothing else, so any test here uses only external fakes by construction.
private func makeViewModel(
    permission: AccessibilityPermissionStub = .init(),
    tap: KeyEventTapFake = .init(),
    poster: VirtualKeyPosterSpy = .init(),
    loginItem: LoginItemServiceFake = .init(),
    settingsOpener: SettingsOpenerSpy = .init()
) -> ContentViewModel {
    ContentViewModel(
        permission: permission,
        eventTap: tap,
        poster: poster,
        loginItem: loginItem,
        settingsOpener: settingsOpener
    )
}

private let controlShift: KeyModifiers = [.control, .shift]
private let unmappedKey = KeyCode(0) // ANSI A

struct ContentViewModelTests {
    // MARK: - Permission and interception lifecycle

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

    // MARK: - Remapping

    @Test
    func shouldRouteInterceptedEventsThroughTheRemapper() {
        // Arrange
        let permission = AccessibilityPermissionStub()
        permission.isTrustedValue = true
        let tap = KeyEventTapFake()
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(permission: permission, tap: tap, poster: poster)

        // Act
        let swallowed = tap.simulate(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Assert
        #expect(viewModel.isTrusted)
        #expect(swallowed)
        #expect(poster.postedKeys == [.jisKana])
    }

    @Test(arguments: [(KeyCode.ansiJ, KeyCode.jisKana), (.ansiSemicolon, .jisEisu)])
    func shouldRemapEachChordToItsInputSourceKey(pressed: KeyCode, posted: KeyCode) {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyDown, keyCode: pressed, modifiers: controlShift)

        // Assert
        #expect(swallowed)
        #expect(poster.postedKeys == [posted])
    }

    @Test
    func shouldPassThroughUnmappedKeys() {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyDown, keyCode: unmappedKey, modifiers: controlShift)

        // Assert
        #expect(!swallowed)
        #expect(poster.postedKeys.isEmpty)
    }

    @Test(arguments: [KeyModifiers.control, .shift, []])
    func shouldNotRemapWithoutFullChord(modifiers: KeyModifiers) {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiJ, modifiers: modifiers)

        // Assert
        #expect(!swallowed)
        #expect(poster.postedKeys.isEmpty)
    }

    @Test(arguments: [KeyModifiers.command, .option])
    func shouldNotRemapWhenABlockingModifierIsHeld(blocker: KeyModifiers) {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)
        let modifiers = controlShift.union(blocker)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiJ, modifiers: modifiers)

        // Assert
        #expect(!swallowed)
        #expect(poster.postedKeys.isEmpty)
    }

    @Test
    func shouldRemapEvenWithUncheckedModifiers() {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)
        let modifiers = controlShift.union(.capsLock)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiJ, modifiers: modifiers)

        // Assert
        #expect(swallowed)
        #expect(poster.postedKeys == [.jisKana])
    }

    @Test
    func shouldSwallowKeyUpOfInterceptedKey() {
        // Arrange
        let viewModel = makeViewModel()
        _ = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyUp, keyCode: .ansiJ, modifiers: [])

        // Assert
        #expect(swallowed)
    }

    @Test
    func shouldSwallowKeyUpOnlyOncePerKeyDown() {
        // Arrange
        let viewModel = makeViewModel()
        _ = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        _ = viewModel.handleKeyEvent(phase: .keyUp, keyCode: .ansiJ, modifiers: [])

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyUp, keyCode: .ansiJ, modifiers: [])

        // Assert
        #expect(!swallowed)
    }

    @Test
    func shouldPassThroughUnrelatedKeyUp() {
        // Arrange
        let viewModel = makeViewModel()

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyUp, keyCode: .ansiJ, modifiers: [])

        // Assert
        #expect(!swallowed)
    }

    @Test
    func shouldRemapAutorepeatedKeyDowns() {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)
        _ = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Assert
        #expect(swallowed)
        #expect(poster.postedKeys == [.jisKana, .jisKana])
    }

    @Test
    func shouldPassThroughNonKeyEvents() {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .other, keyCode: .ansiJ, modifiers: controlShift)

        // Assert
        #expect(!swallowed)
        #expect(poster.postedKeys.isEmpty)
    }

    // MARK: - Launch at login

    @Test(arguments: [true, false])
    func shouldReflectLoginItemStateAtInit(registered: Bool) {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: registered)

        // Act
        let viewModel = makeViewModel(loginItem: loginItem)

        // Assert
        #expect(viewModel.isLaunchAtLoginEnabled == registered)
        #expect(loginItem.receivedRequests.isEmpty)
    }

    @Test
    func shouldRegisterWhenLaunchAtLoginEnabled() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: false)
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = true

        // Assert
        #expect(loginItem.receivedRequests == [true])
        #expect(loginItem.isEnabled)
    }

    @Test
    func shouldUnregisterWhenLaunchAtLoginDisabled() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: true)
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = false

        // Assert
        #expect(loginItem.receivedRequests == [false])
        #expect(!loginItem.isEnabled)
    }

    @Test
    func shouldRevertWhenRegistrationFails() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: false)
        loginItem.nextError = FakeError()
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = true

        // Assert
        #expect(!viewModel.isLaunchAtLoginEnabled)
        #expect(loginItem.receivedRequests == [true])
    }

    @Test
    func shouldRevertWhenUnregistrationFails() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: true)
        loginItem.nextError = FakeError()
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = false

        // Assert
        #expect(viewModel.isLaunchAtLoginEnabled)
        #expect(loginItem.receivedRequests == [false])
    }

    @Test
    func shouldIgnoreRedundantLaunchAtLoginAssignment() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: false)
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = false

        // Assert
        #expect(loginItem.receivedRequests.isEmpty)
    }

    // MARK: - Settings

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
