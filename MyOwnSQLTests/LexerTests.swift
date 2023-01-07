//
//  MyOwnSQLTests.swift
//  MyOwnSQLTests
//
//  Created by Danielle Kefford on 1/6/23.
//

import XCTest

class LexerTests: XCTestCase {
    func testSuccessfulStringParses() throws {
        let location = Location(line: 0, column: 0)
        let cursor = Cursor(pointer: 0, location: location)

        for (testString, expectedTokenValue) in [
            ("'foo'", "foo"),
            ("'foo bar'", "foo bar"),
            ("'foo'   ", "foo"),
            ("'I''m working'", "I''m working"),
        ] {
            let (actualToken, _, actualParsed) = lexString(testString, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .string)
        }
    }

    func testFailedStringParses() throws {
        let location = Location(line: 0, column: 0)
        let cursor = Cursor(pointer: 0, location: location)

        for testString in ["'", "", "foo", " 'foo'"] {
            let (actualToken, _, actualParsed) = lexString(testString, cursor)
            XCTAssertFalse(actualParsed)
            XCTAssertNil(actualToken)
        }
    }
}
