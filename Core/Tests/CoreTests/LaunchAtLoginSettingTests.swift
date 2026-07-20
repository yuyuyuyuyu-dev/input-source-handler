//
//  LaunchAtLoginSettingTests.swift
//  CoreTests
//

@testable import Core
import Testing

struct LaunchAtLoginSettingTests {
    @Test(arguments: [true, false])
    func shouldReflectSystemStateAtInit(registered: Bool) {
        // Arrange
        let service = LoginItemServiceFake(isEnabled: registered)

        // Act
        let setting = LaunchAtLoginSetting(service: service)

        // Assert
        #expect(setting.isEnabled == registered)
        #expect(service.receivedRequests.isEmpty)
    }

    @Test
    func shouldRegisterWhenEnabled() {
        // Arrange
        let service = LoginItemServiceFake(isEnabled: false)
        let setting = LaunchAtLoginSetting(service: service)

        // Act
        setting.isEnabled = true

        // Assert
        #expect(service.receivedRequests == [true])
        #expect(service.isEnabled)
    }

    @Test
    func shouldUnregisterWhenDisabled() {
        // Arrange
        let service = LoginItemServiceFake(isEnabled: true)
        let setting = LaunchAtLoginSetting(service: service)

        // Act
        setting.isEnabled = false

        // Assert
        #expect(service.receivedRequests == [false])
        #expect(!service.isEnabled)
    }

    @Test
    func shouldRevertWhenRegistrationFails() {
        // Arrange
        let service = LoginItemServiceFake(isEnabled: false)
        service.nextError = FakeError()
        let setting = LaunchAtLoginSetting(service: service)

        // Act
        setting.isEnabled = true

        // Assert
        #expect(!setting.isEnabled)
        #expect(service.receivedRequests == [true])
    }

    @Test
    func shouldRevertWhenUnregistrationFails() {
        // Arrange
        let service = LoginItemServiceFake(isEnabled: true)
        service.nextError = FakeError()
        let setting = LaunchAtLoginSetting(service: service)

        // Act
        setting.isEnabled = false

        // Assert
        #expect(setting.isEnabled)
        #expect(service.receivedRequests == [false])
    }

    @Test
    func shouldIgnoreRedundantAssignment() {
        // Arrange
        let service = LoginItemServiceFake(isEnabled: false)
        let setting = LaunchAtLoginSetting(service: service)

        // Act
        setting.isEnabled = false

        // Assert
        #expect(service.receivedRequests.isEmpty)
    }
}
