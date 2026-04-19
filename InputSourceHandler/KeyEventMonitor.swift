import Cocoa
import CoreGraphics
import Combine

class KeyEventMonitor: ObservableObject {
    @Published var isTrusted: Bool = false
    private var eventTap: CFMachPort?
    private var timer: Timer?

    init() {
        checkAccessibility(prompt: true)
        
        // If accessibility permission is not granted, check periodically until it is
        if !isTrusted {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.checkAccessibility(prompt: false)
                if self?.isTrusted == true {
                    self?.startTap()
                    self?.timer?.invalidate()
                    self?.timer = nil
                }
            }
        } else {
            startTap()
        }
    }

    func checkAccessibility(prompt: Bool) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        DispatchQueue.main.async {
            if self.isTrusted != trusted {
                self.isTrusted = trusted
            }
        }
    }

    func startTap() {
        guard eventTap == nil else { return }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: cgEventCallback,
            userInfo: nil
        )

        guard let tap = tap else {
            print("Failed to create event tap")
            return
        }

        self.eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}

fileprivate var interceptedKeyCodes: Set<Int64> = []

private func cgEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    
    if type == .keyUp {
        if interceptedKeyCodes.contains(keyCode) {
            interceptedKeyCodes.remove(keyCode)
            return nil // Discard the keyUp event corresponding to the intercepted keyDown
        }
        return Unmanaged.passUnretained(event)
    }
    
    if type == .keyDown {
        let flags = event.flags
        
        let hasControl = flags.contains(.maskControl)
        let hasShift = flags.contains(.maskShift)
        let hasCommand = flags.contains(.maskCommand)
        let hasOption = flags.contains(.maskAlternate)
        
        // Only Control + Shift are pressed (Command and Option are not pressed)
        if hasControl && hasShift && !hasCommand && !hasOption {
            if keyCode == 38 { // J
                interceptedKeyCodes.insert(keyCode)
                postVirtualKey(keyCode: 104) // Kana
                return nil // Discard original event
            } else if keyCode == 41 { // ;
                interceptedKeyCodes.insert(keyCode)
                postVirtualKey(keyCode: 102) // Eisu (Alphanumeric)
                return nil // Discard original event
            }
        }
    }
    
    return Unmanaged.passUnretained(event)
}

private func postVirtualKey(keyCode: CGKeyCode) {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    
    // Clear modifier flags so that physical modifiers (Control, Shift) don't leak into virtual events
    keyDown?.flags = CGEventFlags()
    keyUp?.flags = CGEventFlags()
    
    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}
