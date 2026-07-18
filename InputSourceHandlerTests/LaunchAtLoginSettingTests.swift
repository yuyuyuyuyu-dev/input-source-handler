//
//  LaunchAtLoginSettingTests.swift
//  InputSourceHandlerTests
//

@testable import InputSourceHandler
import Testing

struct LaunchAtLoginSettingTests {
    @Test("初期値はシステムの登録状態を反映し、登録操作は行わない", arguments: [true, false])
    func initialValueReflectsSystemState(registered: Bool) {
        let service = LoginItemServiceFake(isEnabled: registered)

        let setting = LaunchAtLoginSetting(service: service)

        #expect(setting.isEnabled == registered)
        #expect(service.receivedRequests.isEmpty)
    }

    @Test("有効にするとシステムへ登録を要求する")
    func enableRegisters() {
        let service = LoginItemServiceFake(isEnabled: false)
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = true

        #expect(service.receivedRequests == [true])
        #expect(service.isEnabled)
    }

    @Test("無効にするとシステムへ解除を要求する")
    func disableUnregisters() {
        let service = LoginItemServiceFake(isEnabled: true)
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = false

        #expect(service.receivedRequests == [false])
        #expect(!service.isEnabled)
    }

    @Test("登録に失敗したら、トグルは実際の登録状態へ戻る")
    func revertsWhenRegistrationFails() {
        let service = LoginItemServiceFake(isEnabled: false)
        service.nextError = FakeError()
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = true

        #expect(!setting.isEnabled)
        #expect(service.receivedRequests == [true])
    }

    @Test("解除に失敗したら、トグルは実際の登録状態へ戻る")
    func revertsWhenUnregistrationFails() {
        let service = LoginItemServiceFake(isEnabled: true)
        service.nextError = FakeError()
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = false

        #expect(setting.isEnabled)
        #expect(service.receivedRequests == [false])
    }

    @Test("値が変わらない代入ではシステムを呼ばない")
    func ignoresRedundantAssignment() {
        let service = LoginItemServiceFake(isEnabled: false)
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = false

        #expect(service.receivedRequests.isEmpty)
    }
}
