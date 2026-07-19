//
//  TestRunDetectionTests.swift
//  InputSourceHandlerTests
//

import Foundation
@testable import InputSourceHandler
import Testing

// Canary: the app relies on this detection to keep the real permission prompt
// and event tap out of test runs. If a toolchain update changes the environment
// variables, this test fails loudly instead of dialogs quietly coming back.
struct TestRunDetectionTests {
    @Test
    func shouldDetectTestRun() {
        let xctestKeys = ProcessInfo.processInfo.environment.keys.filter { $0.contains("XCTest") }
        #expect(ProcessInfo.processInfo.isRunningTests, "XCTest-related environment keys: \(xctestKeys)")
    }
}
