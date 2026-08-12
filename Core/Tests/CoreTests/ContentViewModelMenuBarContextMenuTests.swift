//
//  ContentViewModelMenuBarContextMenuTests.swift
//  CoreTests
//

@testable import Core
import Testing

struct ContentViewModelMenuBarContextMenuTests {
    @Test
    func shouldQuitTheAppFromTheMenuBarContextMenu() throws {
        // Arrange
        let terminator = AppTerminatorSpy()
        let viewModel = makeViewModel(terminator: terminator)
        let quit = try #require(viewModel.menuBarContextMenu.first { $0 == .quit })

        // Act
        viewModel.perform(quit)

        // Assert
        #expect(terminator.terminateCount == 1)
    }
}
