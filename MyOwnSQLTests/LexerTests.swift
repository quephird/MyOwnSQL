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

        for testString in ["'", "", "foo", " 'foo'", "'foo     "] {
            let (actualToken, _, actualParsed) = lexString(testString, cursor)
            XCTAssertFalse(actualParsed)
            XCTAssertNil(actualToken)
        }
    }

    func testSuccessfulNumericParses() throws {
        let location = Location(line: 0, column: 0)
        let cursor = Cursor(pointer: 0, location: location)

        for (testNumeric, expectedTokenValue) in [
            ("123", "123"),
            (".123", ".123"),
            ("0.123", "0.123"),
            ("123.456", "123.456"),
            ("1.23e4", "1.23e4"),
            ("1.23e+4", "1.23e+4"),
            ("1.23e-4", "1.23e-4"),
        ] {
            let (actualToken, _, actualParsed) = lexNumeric(testNumeric, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .numeric)
        }
    }
}
