//
//  ShortcutRemapperTests.swift
//  CoreTests
//

@testable import Core
import Testing

private let controlShift: KeyModifiers = [.control, .shift]
private let unmappedKey = KeyCode(0) // ANSI A

struct ShortcutRemapperTests {
    @Test
    func shouldRemapControlShiftJToKana() {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Assert
        #expect(action == .discardAndPost(.jisKana))
    }

    @Test
    func shouldRemapControlShiftSemicolonToEisu() {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiSemicolon, modifiers: controlShift)

        // Assert
        #expect(action == .discardAndPost(.jisEisu))
    }

    @Test
    func shouldPassThroughUnmappedKeys() {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .keyDown, keyCode: unmappedKey, modifiers: controlShift)

        // Assert
        #expect(action == .passThrough)
    }

    @Test(arguments: [KeyModifiers.control, .shift, []])
    func shouldNotRemapWithoutFullChord(modifiers: KeyModifiers) {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: modifiers)

        // Assert
        #expect(action == .passThrough)
    }

    @Test
    func shouldNotRemapWhenCommandIsHeld() {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift.union(.command))

        // Assert
        #expect(action == .passThrough)
    }

    @Test
    func shouldNotRemapWhenOptionIsHeld() {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift.union(.option))

        // Assert
        #expect(action == .passThrough)
    }

    @Test
    func shouldRemapEvenWithUncheckedModifiers() {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift.union(.capsLock))

        // Assert
        #expect(action == .discardAndPost(.jisKana))
    }

    @Test
    func shouldSwallowKeyUpOfInterceptedKey() {
        // Arrange
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Act
        let action = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: controlShift)

        // Assert
        #expect(action == .discard)
    }

    @Test
    func shouldSwallowKeyUpEvenAfterModifiersReleased() {
        // Arrange
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Act
        let action = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: [])

        // Assert
        #expect(action == .discard)
    }

    @Test
    func shouldSwallowKeyUpOnlyOncePerKeyDown() {
        // Arrange
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        _ = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: [])

        // Act
        let action = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: [])

        // Assert
        #expect(action == .passThrough)
    }

    @Test
    func shouldPassThroughUnrelatedKeyUp() {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: [])

        // Assert
        #expect(action == .passThrough)
    }

    @Test
    func shouldTrackMultipleInterceptedKeys() {
        // Arrange
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiSemicolon, modifiers: controlShift)

        // Act & Assert
        #expect(remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: []) == .discard)
        #expect(remapper.handle(phase: .keyUp, keyCode: .ansiSemicolon, modifiers: []) == .discard)
    }

    @Test
    func shouldRemapAutorepeatedKeyDowns() {
        // Arrange
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Act
        let repeated = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)

        // Assert
        #expect(repeated == .discardAndPost(.jisKana))
    }

    @Test
    func shouldPassThroughNonKeyEvents() {
        // Arrange
        var remapper = ShortcutRemapper()

        // Act
        let action = remapper.handle(phase: .other, keyCode: .ansiJ, modifiers: controlShift)

        // Assert
        #expect(action == .passThrough)
    }
}
