//
//  ShortcutRemapper.swift
//  Core
//

import Carbon.HIToolbox
import CoreGraphics

/// Decides what to do with each keyboard event.
/// Pure logic with no system calls, so it is fully testable.
public struct ShortcutRemapper {
    public enum Action: Equatable {
        /// Let the event through unchanged.
        case passThrough
        /// Swallow the event (e.g. the keyUp of an already replaced keyDown).
        case discard
        /// Swallow the event and post the given virtual key instead.
        case discardAndPost(CGKeyCode)
    }

    /// Key codes whose keyDown was swallowed; the matching keyUp must be swallowed too.
    private var interceptedKeyCodes: Set<Int64> = []

    public init() {}

    public mutating func handle(type: CGEventType, keyCode: Int64, flags: CGEventFlags) -> Action {
        switch type {
        case .keyDown:
            guard isTriggerChord(flags), let replacement = Self.replacement(for: keyCode) else {
                return .passThrough
            }
            interceptedKeyCodes.insert(keyCode)
            return .discardAndPost(replacement)
        case .keyUp:
            guard interceptedKeyCodes.remove(keyCode) != nil else {
                return .passThrough
            }
            return .discard
        default:
            return .passThrough
        }
    }

    /// Control + Shift are pressed, Command and Option are not.
    private func isTriggerChord(_ flags: CGEventFlags) -> Bool {
        flags.contains(.maskControl) && flags.contains(.maskShift)
            && !flags.contains(.maskCommand) && !flags.contains(.maskAlternate)
    }

    private static func replacement(for keyCode: Int64) -> CGKeyCode? {
        switch keyCode {
        case Int64(kVK_ANSI_J):
            CGKeyCode(kVK_JIS_Kana)
        case Int64(kVK_ANSI_Semicolon):
            CGKeyCode(kVK_JIS_Eisu)
        default:
            nil
        }
    }
}
