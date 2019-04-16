import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Rewind_OpenEmuXPCCommunicatorTests.allTests),
    ]
}
#endif