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

        for (testString, expectedTokenValue) in [
            ("'foo'", "foo"),
            ("'foo bar'", "foo bar"),
            ("'foo'   ", "foo"),
            ("'I''m working'", "I''m working"),
        ] {
            let cursor = Cursor(pointer: testString.startIndex, location: location)
            let (actualToken, _, actualParsed) = lexString(testString, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .string)
        }
    }

    func testFailedStringParses() throws {
        let location = Location(line: 0, column: 0)

        for testString in ["'", "", "foo", " 'foo'", "'foo     "] {
            let cursor = Cursor(pointer: testString.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexString(testString, cursor)
            XCTAssertFalse(actualParsed)
            XCTAssertNil(actualToken)
        }
    }

    func testSuccessfulNumericParses() throws {
        let location = Location(line: 0, column: 0)

        for (testNumeric, expectedTokenValue) in [
            ("123", "123"),
            (".123", ".123"),
            ("0.123", "0.123"),
            ("123.456", "123.456"),
            ("1.23e4", "1.23e4"),
            ("1.23e+4", "1.23e+4"),
            ("1.23e-4", "1.23e-4"),
            ("12345       ", "12345"),
        ] {
            let cursor = Cursor(pointer: testNumeric.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexNumeric(testNumeric, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .numeric)
        }
    }

    func testFailedNumericParses() throws {
        let location = Location(line: 0, column: 0)

        for testNumeric in ["'foo'", "1.23e", "123..456", "123ee456", "123ed456", "123e*4", "e123"] {
            let cursor = Cursor(pointer: testNumeric.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexNumeric(testNumeric, cursor)
            XCTAssertFalse(actualParsed)
            XCTAssertNil(actualToken)
        }
    }
}
