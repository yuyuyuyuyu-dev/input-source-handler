//
//  ShortcutRemapper.swift
//  Core
//

/// Decides what to do with each keyboard event.
/// Pure logic with no system calls, so it is fully testable.
public struct ShortcutRemapper {
    public enum Action: Equatable {
        /// Let the event through unchanged.
        case passThrough
        /// Swallow the event (e.g. the keyUp of an already replaced keyDown).
        case discard
        /// Swallow the event and post the given virtual key instead.
        case discardAndPost(KeyCode)
    }

    /// Key codes whose keyDown was swallowed; the matching keyUp must be swallowed too.
    private var interceptedKeyCodes: Set<KeyCode> = []

    public init() {}

    public mutating func handle(phase: KeyEventPhase, keyCode: KeyCode, modifiers: KeyModifiers) -> Action {
        switch phase {
        case .keyDown:
            guard isTriggerChord(modifiers), let replacement = Self.replacement(for: keyCode) else {
                return .passThrough
            }
            interceptedKeyCodes.insert(keyCode)
            return .discardAndPost(replacement)
        case .keyUp:
            guard interceptedKeyCodes.remove(keyCode) != nil else {
                return .passThrough
            }
            return .discard
        case .other:
            return .passThrough
        }
    }

    /// Control + Shift are pressed, Command and Option are not.
    private func isTriggerChord(_ modifiers: KeyModifiers) -> Bool {
        modifiers.contains(.control) && modifiers.contains(.shift)
            && !modifiers.contains(.command) && !modifiers.contains(.option)
    }

    private static func replacement(for keyCode: KeyCode) -> KeyCode? {
        switch keyCode {
        case .ansiJ:
            .jisKana
        case .ansiSemicolon:
            .jisEisu
        default:
            nil
        }
    }
}
