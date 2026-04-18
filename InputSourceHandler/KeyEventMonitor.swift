import Cocoa
import CoreGraphics
import Combine

class KeyEventMonitor: ObservableObject {
    @Published var isTrusted: Bool = false
    private var eventTap: CFMachPort?
    private var timer: Timer?

    init() {
        checkAccessibility(prompt: true)
        
        // もし権限がない場合は、定期的にチェックして権限が付与されたら開始する
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
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: cgEventCallback,
            userInfo: nil
        )

        guard let tap = tap else {
            print("Event tapの作成に失敗しました")
            return
        }

        self.eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}

private func cgEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags
    
    let hasControl = flags.contains(.maskControl)
    let hasShift = flags.contains(.maskShift)
    let hasCommand = flags.contains(.maskCommand)
    let hasOption = flags.contains(.maskAlternate)
    
    // Control + Shift のみが押されている状態 (CommandとOptionは押されていない)
    if hasControl && hasShift && !hasCommand && !hasOption {
        if keyCode == 38 { // J
            postVirtualKey(keyCode: 104) // かな
            return nil // 元のイベントを破棄
        } else if keyCode == 41 { // ;
            postVirtualKey(keyCode: 102) // 英数
            return nil // 元のイベントを破棄
        }
    }
    
    return Unmanaged.passUnretained(event)
}

private func postVirtualKey(keyCode: CGKeyCode) {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    
    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}
