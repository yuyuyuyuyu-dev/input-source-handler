//
//  ContentViewModelLaunchAtLoginTests.swift
//  CoreTests
//

@testable import Core
import Testing

struct ContentViewModelLaunchAtLoginTests {
    @Test(arguments: [true, false])
    func shouldReflectLoginItemStateAtInit(registered: Bool) {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: registered)

        // Act
        let viewModel = makeViewModel(loginItem: loginItem)

        // Assert
        #expect(viewModel.isLaunchAtLoginEnabled == registered)
        #expect(loginItem.receivedRequests.isEmpty)
    }

    @Test
    func shouldRegisterWhenLaunchAtLoginEnabled() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: false)
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = true

        // Assert
        #expect(loginItem.receivedRequests == [true])
        #expect(loginItem.isEnabled)
    }

    @Test
    func shouldUnregisterWhenLaunchAtLoginDisabled() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: true)
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = false

        // Assert
        #expect(loginItem.receivedRequests == [false])
        #expect(!loginItem.isEnabled)
    }

    @Test
    func shouldRevertWhenRegistrationFails() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: false)
        loginItem.nextError = FakeError()
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = true

        // Assert
        #expect(!viewModel.isLaunchAtLoginEnabled)
        #expect(loginItem.receivedRequests == [true])
    }

    @Test
    func shouldRevertWhenUnregistrationFails() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: true)
        loginItem.nextError = FakeError()
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = false

        // Assert
        #expect(viewModel.isLaunchAtLoginEnabled)
        #expect(loginItem.receivedRequests == [false])
    }

    @Test
    func shouldIgnoreRedundantLaunchAtLoginAssignment() {
        // Arrange
        let loginItem = LoginItemServiceFake(isEnabled: false)
        let viewModel = makeViewModel(loginItem: loginItem)

        // Act
        viewModel.isLaunchAtLoginEnabled = false

        // Assert
        #expect(loginItem.receivedRequests.isEmpty)
    }
}
