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
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        #expect(action == .discardAndPost(.jisKana))
    }

    @Test
    func shouldRemapControlShiftSemicolonToEisu() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiSemicolon, modifiers: controlShift)
        #expect(action == .discardAndPost(.jisEisu))
    }

    @Test
    func shouldPassThroughUnmappedKeys() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .keyDown, keyCode: unmappedKey, modifiers: controlShift)
        #expect(action == .passThrough)
    }

    @Test(arguments: [KeyModifiers.control, .shift, []])
    func shouldNotRemapWithoutFullChord(modifiers: KeyModifiers) {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: modifiers)
        #expect(action == .passThrough)
    }

    @Test
    func shouldNotRemapWhenCommandIsHeld() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift.union(.command))
        #expect(action == .passThrough)
    }

    @Test
    func shouldNotRemapWhenOptionIsHeld() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift.union(.option))
        #expect(action == .passThrough)
    }

    @Test
    func shouldRemapEvenWithUncheckedModifiers() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift.union(.capsLock))
        #expect(action == .discardAndPost(.jisKana))
    }

    @Test
    func shouldSwallowKeyUpOfInterceptedKey() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        let action = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: controlShift)
        #expect(action == .discard)
    }

    @Test
    func shouldSwallowKeyUpEvenAfterModifiersReleased() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        let action = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: [])
        #expect(action == .discard)
    }

    @Test
    func shouldSwallowKeyUpOnlyOncePerKeyDown() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        _ = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: [])
        let action = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: [])
        #expect(action == .passThrough)
    }

    @Test
    func shouldPassThroughUnrelatedKeyUp() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: [])
        #expect(action == .passThrough)
    }

    @Test
    func shouldTrackMultipleInterceptedKeys() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiSemicolon, modifiers: controlShift)
        #expect(remapper.handle(phase: .keyUp, keyCode: .ansiJ, modifiers: []) == .discard)
        #expect(remapper.handle(phase: .keyUp, keyCode: .ansiSemicolon, modifiers: []) == .discard)
    }

    @Test
    func shouldRemapAutorepeatedKeyDowns() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        let repeated = remapper.handle(phase: .keyDown, keyCode: .ansiJ, modifiers: controlShift)
        #expect(repeated == .discardAndPost(.jisKana))
    }

    @Test
    func shouldPassThroughNonKeyEvents() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(phase: .other, keyCode: .ansiJ, modifiers: controlShift)
        #expect(action == .passThrough)
    }
}
