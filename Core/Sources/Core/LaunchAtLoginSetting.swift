//
//  LaunchAtLoginSetting.swift
//  Core
//

import Foundation
import Observation

/// Mirrors the "launch at login" registration state and reverts the toggle when a change fails.
@Observable
public final class LaunchAtLoginSetting {
    public var isEnabled: Bool {
        didSet { applyChange(from: oldValue) }
    }

    private let service: any LoginItemService
    @ObservationIgnored private var isReverting = false

    public init(service: any LoginItemService) {
        self.service = service
        isEnabled = service.isEnabled
    }

    private func applyChange(from oldValue: Bool) {
        guard !isReverting, isEnabled != oldValue else { return }
        do {
            try service.setEnabled(isEnabled)
        } catch {
            print("Failed to change login item: \(error)")
            isReverting = true
            isEnabled = service.isEnabled
            isReverting = false
        }
    }
}
