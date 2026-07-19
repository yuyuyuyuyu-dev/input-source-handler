//
//  LaunchAtLoginSettingTests.swift
//  CoreTests
//

@testable import Core
import Testing

struct LaunchAtLoginSettingTests {
    @Test(arguments: [true, false])
    func shouldReflectSystemStateAtInit(registered: Bool) {
        let service = LoginItemServiceFake(isEnabled: registered)

        let setting = LaunchAtLoginSetting(service: service)

        #expect(setting.isEnabled == registered)
        #expect(service.receivedRequests.isEmpty)
    }

    @Test
    func shouldRegisterWhenEnabled() {
        let service = LoginItemServiceFake(isEnabled: false)
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = true

        #expect(service.receivedRequests == [true])
        #expect(service.isEnabled)
    }

    @Test
    func shouldUnregisterWhenDisabled() {
        let service = LoginItemServiceFake(isEnabled: true)
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = false

        #expect(service.receivedRequests == [false])
        #expect(!service.isEnabled)
    }

    @Test
    func shouldRevertWhenRegistrationFails() {
        let service = LoginItemServiceFake(isEnabled: false)
        service.nextError = FakeError()
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = true

        #expect(!setting.isEnabled)
        #expect(service.receivedRequests == [true])
    }

    @Test
    func shouldRevertWhenUnregistrationFails() {
        let service = LoginItemServiceFake(isEnabled: true)
        service.nextError = FakeError()
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = false

        #expect(setting.isEnabled)
        #expect(service.receivedRequests == [false])
    }

    @Test
    func shouldIgnoreRedundantAssignment() {
        let service = LoginItemServiceFake(isEnabled: false)
        let setting = LaunchAtLoginSetting(service: service)

        setting.isEnabled = false

        #expect(service.receivedRequests.isEmpty)
    }
}
