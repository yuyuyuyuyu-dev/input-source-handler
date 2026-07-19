//
//  ShortcutRemapperTests.swift
//  CoreTests
//

import Carbon.HIToolbox
@testable import Core
import CoreGraphics
import Testing

private let keyJ = Int64(kVK_ANSI_J)
private let keySemicolon = Int64(kVK_ANSI_Semicolon)
private let keyA = Int64(kVK_ANSI_A)
private let kanaKey = CGKeyCode(kVK_JIS_Kana)
private let eisuKey = CGKeyCode(kVK_JIS_Eisu)
private let controlShift: CGEventFlags = [.maskControl, .maskShift]

struct ShortcutRemapperTests {
    @Test
    func shouldRemapControlShiftJToKana() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        #expect(action == .discardAndPost(kanaKey))
    }

    @Test
    func shouldRemapControlShiftSemicolonToEisu() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keySemicolon, flags: controlShift)
        #expect(action == .discardAndPost(eisuKey))
    }

    @Test
    func shouldPassThroughUnmappedKeys() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyA, flags: controlShift)
        #expect(action == .passThrough)
    }

    @Test(arguments: [CGEventFlags.maskControl, .maskShift, []])
    func shouldNotRemapWithoutFullChord(flags: CGEventFlags) {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: flags)
        #expect(action == .passThrough)
    }

    @Test
    func shouldNotRemapWhenCommandIsHeld() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift.union(.maskCommand))
        #expect(action == .passThrough)
    }

    @Test
    func shouldNotRemapWhenOptionIsHeld() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift.union(.maskAlternate))
        #expect(action == .passThrough)
    }

    @Test
    func shouldRemapEvenWithUncheckedModifiers() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift.union(.maskAlphaShift))
        #expect(action == .discardAndPost(kanaKey))
    }

    @Test
    func shouldSwallowKeyUpOfInterceptedKey() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        let action = remapper.handle(type: .keyUp, keyCode: keyJ, flags: controlShift)
        #expect(action == .discard)
    }

    @Test
    func shouldSwallowKeyUpEvenAfterModifiersReleased() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        let action = remapper.handle(type: .keyUp, keyCode: keyJ, flags: [])
        #expect(action == .discard)
    }

    @Test
    func shouldSwallowKeyUpOnlyOncePerKeyDown() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        _ = remapper.handle(type: .keyUp, keyCode: keyJ, flags: [])
        let action = remapper.handle(type: .keyUp, keyCode: keyJ, flags: [])
        #expect(action == .passThrough)
    }

    @Test
    func shouldPassThroughUnrelatedKeyUp() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyUp, keyCode: keyJ, flags: [])
        #expect(action == .passThrough)
    }

    @Test
    func shouldTrackMultipleInterceptedKeys() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        _ = remapper.handle(type: .keyDown, keyCode: keySemicolon, flags: controlShift)
        #expect(remapper.handle(type: .keyUp, keyCode: keyJ, flags: []) == .discard)
        #expect(remapper.handle(type: .keyUp, keyCode: keySemicolon, flags: []) == .discard)
    }

    @Test
    func shouldRemapAutorepeatedKeyDowns() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        let repeated = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        #expect(repeated == .discardAndPost(kanaKey))
    }

    @Test
    func shouldPassThroughNonKeyEvents() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .flagsChanged, keyCode: keyJ, flags: controlShift)
        #expect(action == .passThrough)
    }
}
