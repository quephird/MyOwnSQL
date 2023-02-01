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

    func testSuccessfulKeywordParses() throws {
        let location = Location(line: 0, column: 0)

        for (testSource, expectedTokenValue) in [
            ("select ", "select"),
            ("SELECT ", "select"),
            ("from", "from"),
        ] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let (actualToken, newCursor, actualParsed) = lexKeyword(testSource, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .keyword)
            XCTAssertEqual(newCursor.location.column, cursor.location.column + actualToken!.value.count)
        }
    }

    func testFailedKeywordParses() throws {
        let location = Location(line: 0, column: 0)

        for testSource in ["'foo'", "1.23e456", " select", "non-existent"] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexKeyword(testSource, cursor)
            XCTAssertFalse(actualParsed)
            XCTAssertNil(actualToken)
        }
    }

    func testSuccessfulIdentifierParses() throws {
        let location = Location(line: 0, column: 0)

        for (testSource, expectedTokenValue) in [
            ("\"foo\"", "foo"),
            ("foo", "foo"),
            ("foo$bar_baz", "foo$bar_baz"),
            ("foo;", "foo"),
        ] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexIdentifier(testSource, cursor)
            XCTAssertTrue(actualParsed)
            XCTAssertEqual(actualToken!.value, expectedTokenValue)
            XCTAssertEqual(actualToken!.kind, .identifier)
        }
    }

    func testFailedIdentifierParses() throws {
        let location = Location(line: 0, column: 0)

        for testSource in ["\"", "'foo'", "1.23e456", "$foo", "9foo", "_foo"] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let (actualToken, _, actualParsed) = lexIdentifier(testSource, cursor)
            XCTAssertFalse(actualParsed)
            XCTAssertNil(actualToken)
        }
    }

    func testSuccessfulLex() throws {
        let source = """
SELECT 'x' FROM foo
WHERE bar = 42;
"""
        let (actualTokens, actualErrorMessage) = lex(source)

        let expectedTokens = [
            Token(value: "select", kind: .keyword, location: Location(line: 0, column: 0)),
            Token(value: "x", kind: .string, location: Location(line: 0, column: 7)),
            Token(value: "from", kind: .keyword, location: Location(line: 0, column: 11)),
            Token(value: "foo", kind: .identifier, location: Location(line: 0, column: 16)),
            Token(value: "where", kind: .keyword, location: Location(line: 1, column: 0)),
            Token(value: "bar", kind: .identifier, location: Location(line: 1, column: 6)),
            Token(value: "=", kind: .symbol, location: Location(line: 1, column: 10)),
            Token(value: "42", kind: .numeric, location: Location(line: 1, column: 12)),
            Token(value: ";", kind: .symbol, location: Location(line: 1, column: 14)),
        ]
        XCTAssertEqual(actualTokens!, expectedTokens)
        XCTAssertNil(actualErrorMessage)
    }
}
