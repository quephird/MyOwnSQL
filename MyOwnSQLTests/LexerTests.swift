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

        for (testSource, expectedTokenValue) in [
            ("'foo'", "foo"),
            ("'foo bar'", "foo bar"),
            ("'foo'   ", "foo"),
            ("'I''m working'", "I''m working"),
        ] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)
            let (actualToken, _, actualParsed) = lexString(testSource, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .string)
        }
    }

    func testFailedStringParses() throws {
        let location = Location(line: 0, column: 0)

        for testSource in ["'", "", "foo", " 'foo'", "'foo     "] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexString(testSource, cursor)
            XCTAssertFalse(actualParsed)
            XCTAssertNil(actualToken)
        }
    }

    func testSuccessfulNumericParses() throws {
        let location = Location(line: 0, column: 0)

        for (testSource, expectedTokenValue) in [
            ("123", "123"),
            (".123", ".123"),
            ("0.123", "0.123"),
            ("123.456", "123.456"),
            ("1.23e4", "1.23e4"),
            ("1.23e+4", "1.23e+4"),
            ("1.23e-4", "1.23e-4"),
            ("12345       ", "12345"),
        ] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexNumeric(testSource, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .numeric)
        }
    }

    func testFailedNumericParses() throws {
        let location = Location(line: 0, column: 0)

        for testSource in ["'foo'", "1.23e", "123..456", "123ee456", "123ed456", "123e*4", "e123"] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexNumeric(testSource, cursor)
            XCTAssertFalse(actualParsed)
            XCTAssertNil(actualToken)
        }
    }

    func testSuccessfulSpaceParse() throws {
        let location = Location(line: 0, column: 3)
        let testSource = "foo bar"
        let pointer = testSource.index(testSource.startIndex, offsetBy: 3)
        let cursor = Cursor(pointer: pointer, location: location)

        let (actualToken, newCursor, actualParsed) = lexSymbol(testSource, cursor)
        XCTAssertTrue(actualParsed)
        XCTAssertNil(actualToken)
        XCTAssertEqual(newCursor.location.line, 0)
        XCTAssertEqual(newCursor.location.column, 4)
    }

    func testSuccessfulNewlineParse() throws {
        let location = Location(line: 0, column: 18)

        let testSource = """
select * from foo;
select * from bar;
"""
        let newlineIndex = testSource.index(testSource.startIndex, offsetBy: 18)
        let cursor = Cursor(pointer: newlineIndex, location: location)

        let (actualToken, newCursor, actualParsed) = lexSymbol(testSource, cursor)
        XCTAssertTrue(actualParsed)
        XCTAssertNil(actualToken)
        XCTAssertEqual(newCursor.location.line, 1)
        XCTAssertEqual(newCursor.location.column, 0)
    }

    func testSuccessfulSymbolicParses() throws {
        let location = Location(line: 0, column: 0)

        for (testSource, expectedTokenValue) in [
            ("(", "("),
            (")", ")"),
            ("* ", "*"),
        ] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexSymbol(testSource, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .symbol)
        }
    }
}
