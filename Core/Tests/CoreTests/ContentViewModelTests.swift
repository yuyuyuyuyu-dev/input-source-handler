//
//  ContentViewModelTests.swift
//  CoreTests
//

@testable import Core
import Testing

private let unmappedKey = KeyCode(0) // ANSI A

struct ContentViewModelTests {
    // MARK: - The two shortcuts this app exists to provide

    @Test
    func shouldRemapControlShiftJToKanaKey() {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Assert
        #expect(poster.postedKeys == [.jisKana])
        #expect(swallowed)
    }

    @Test
    func shouldRemapControlShiftSemicolonToEisuKey() {
        // Arrange
        let poster = VirtualKeyPosterSpy()
        let viewModel = makeViewModel(poster: poster)

        // Act
        let swallowed = viewModel.handleKeyEvent(phase: .keyDown, keyCode: .ansiSemicolon, modifiers: controlShift)

        // Assert
        #expect(poster.postedKeys == [.jisEisu])
        #expect(swallowed)
    }

    // MARK: - Remapping rules

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
}
