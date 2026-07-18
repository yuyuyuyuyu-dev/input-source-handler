//
//  ShortcutRemapperTests.swift
//  InputSourceHandlerTests
//

import Carbon.HIToolbox
import CoreGraphics
@testable import InputSourceHandler
import Testing

private let keyJ = Int64(kVK_ANSI_J)
private let keySemicolon = Int64(kVK_ANSI_Semicolon)
private let keyA = Int64(kVK_ANSI_A)
private let kanaKey = CGKeyCode(kVK_JIS_Kana)
private let eisuKey = CGKeyCode(kVK_JIS_Eisu)
private let controlShift: CGEventFlags = [.maskControl, .maskShift]

struct ShortcutRemapperTests {
    @Test("Control+Shift+J の keyDown は破棄され、かなキーが送出される")
    func remapsJToKana() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        #expect(action == .discardAndPost(kanaKey))
    }

    @Test("Control+Shift+; の keyDown は破棄され、英数キーが送出される")
    func remapsSemicolonToEisu() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keySemicolon, flags: controlShift)
        #expect(action == .discardAndPost(eisuKey))
    }

    @Test("Control+Shift でも対象外のキーはそのまま通す")
    func passesThroughOtherKeys() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyA, flags: controlShift)
        #expect(action == .passThrough)
    }

    @Test("Control と Shift が揃っていなければ変換しない", arguments: [CGEventFlags.maskControl, .maskShift, []])
    func requiresControlAndShift(flags: CGEventFlags) {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: flags)
        #expect(action == .passThrough)
    }

    @Test("Command が同時に押されていたら変換しない")
    func rejectsCommand() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift.union(.maskCommand))
        #expect(action == .passThrough)
    }

    @Test("Option が同時に押されていたら変換しない")
    func rejectsOption() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift.union(.maskAlternate))
        #expect(action == .passThrough)
    }

    @Test("CapsLock など判定対象外の修飾キーが付いていても変換する")
    func allowsUncheckedModifiers() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift.union(.maskAlphaShift))
        #expect(action == .discardAndPost(kanaKey))
    }

    @Test("破棄した keyDown に対応する keyUp も破棄される")
    func swallowsMatchingKeyUp() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        let action = remapper.handle(type: .keyUp, keyCode: keyJ, flags: controlShift)
        #expect(action == .discard)
    }

    @Test("keyUp の破棄は修飾キーが先に離されていても行われる")
    func swallowsKeyUpAfterModifiersReleased() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        let action = remapper.handle(type: .keyUp, keyCode: keyJ, flags: [])
        #expect(action == .discard)
    }

    @Test("keyUp を破棄するのは対応する keyDown 1回につき1度だけ")
    func swallowsKeyUpOnlyOnce() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        _ = remapper.handle(type: .keyUp, keyCode: keyJ, flags: [])
        let action = remapper.handle(type: .keyUp, keyCode: keyJ, flags: [])
        #expect(action == .passThrough)
    }

    @Test("破棄していないキーの keyUp はそのまま通す")
    func passesThroughUnrelatedKeyUp() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .keyUp, keyCode: keyJ, flags: [])
        #expect(action == .passThrough)
    }

    @Test("複数のショートカットを同時に追跡できる")
    func tracksMultipleInterceptedKeys() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        _ = remapper.handle(type: .keyDown, keyCode: keySemicolon, flags: controlShift)
        #expect(remapper.handle(type: .keyUp, keyCode: keyJ, flags: []) == .discard)
        #expect(remapper.handle(type: .keyUp, keyCode: keySemicolon, flags: []) == .discard)
    }

    @Test("キーリピート中の keyDown も毎回変換される")
    func remapsAutorepeatedKeyDowns() {
        var remapper = ShortcutRemapper()
        _ = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        let repeated = remapper.handle(type: .keyDown, keyCode: keyJ, flags: controlShift)
        #expect(repeated == .discardAndPost(kanaKey))
    }

    @Test("keyDown / keyUp 以外のイベントはそのまま通す")
    func passesThroughOtherEventTypes() {
        var remapper = ShortcutRemapper()
        let action = remapper.handle(type: .flagsChanged, keyCode: keyJ, flags: controlShift)
        #expect(action == .passThrough)
    }
}
