//
//  KeyboardTypes.swift
//  Core
//

/// A macOS virtual key code, kept as a Core-owned type so the logic stays free of SDK frameworks.
public struct KeyCode: Hashable, Sendable {
    public let rawValue: Int64

    public init(_ rawValue: Int64) {
        self.rawValue = rawValue
    }
}

public extension KeyCode {
    // Raw values are the stable Mac virtual key codes (kVK_* in Carbon.HIToolbox).
    static let ansiJ = KeyCode(38)
    static let ansiSemicolon = KeyCode(41)
    static let jisKana = KeyCode(104)
    static let jisEisu = KeyCode(102)
}

/// The modifier keys held during a key event.
public struct KeyModifiers: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let control = KeyModifiers(rawValue: 1 << 0)
    public static let shift = KeyModifiers(rawValue: 1 << 1)
    public static let command = KeyModifiers(rawValue: 1 << 2)
    public static let option = KeyModifiers(rawValue: 1 << 3)
    public static let capsLock = KeyModifiers(rawValue: 1 << 4)
}

/// The part of a key event's lifecycle relevant to remapping.
public enum KeyEventPhase: Sendable {
    case keyDown
    case keyUp
    /// Any event that is not a key press, e.g. tap timeout notifications.
    case other
}
