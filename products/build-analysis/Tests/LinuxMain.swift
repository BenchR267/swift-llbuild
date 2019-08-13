import XCTest

import build_analysisTests

var tests = [XCTestCaseEntry]()
tests += build_analysisTests.allTests()
XCTMain(tests)
