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
            let result = lexString(testSource, cursor)
            guard case .success(_, let token?) = result else {
                XCTFail("Lexing failed unexpectedly")
                return
            }
            XCTAssertEqual(token.kind, .string(expectedTokenValue))
        }
    }

    func testFailedStringParses() throws {
        let location = Location(line: 0, column: 0)

        for testSource in ["'", "", "foo", " 'foo'", "'foo     "] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let result = lexString(testSource, cursor)
            XCTAssertEqual(result, .failure)
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

            let result = lexNumeric(testSource, cursor)
            guard case .success(_, let token?) = result else {
                XCTFail("Lexing failed unexpectedly")
                return
            }
            XCTAssertEqual(token.kind, .numeric(expectedTokenValue))
        }
    }

    func testFailedNumericParses() throws {
        let location = Location(line: 0, column: 0)

        for testSource in ["'foo'", "1.23e", "123..456", "123ee456", "123ed456", "123e*4", "e123"] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let result = lexNumeric(testSource, cursor)
            XCTAssertEqual(result, .failure)
        }
    }

    func testSuccessfulSpaceParse() throws {
        let location = Location(line: 0, column: 3)
        let testSource = "foo bar"
        let pointer = testSource.index(testSource.startIndex, offsetBy: 3)
        let cursor = Cursor(pointer: pointer, location: location)

        let result = lexSymbol(testSource, cursor)
        guard case .success(let newCursor, let token) = result else {
            XCTFail("Lexing failed unexpectedly")
            return
        }
        XCTAssertNil(token)
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

        let result = lexSymbol(testSource, cursor)
        guard case .success(let newCursor, let token) = result else {
            XCTFail("Lexing failed unexpectedly")
            return
        }
        XCTAssertNil(token)
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

            let result = lexSymbol(testSource, cursor)
            guard case .success(_, let token?) = result else {
                XCTFail("Lexing failed unexpectedly")
                return
            }
            XCTAssertEqual(token.kind, .symbol(Symbol(rawValue: expectedTokenValue)!))
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

            let result = lexKeyword(testSource, cursor)
            guard case .success(let newCursor, let token?) = result else {
                XCTFail("Lexing failed unexpectedly")
                return
            }
            XCTAssertEqual(token.kind, .keyword(Keyword(rawValue: expectedTokenValue)!))
            XCTAssertEqual(newCursor.location.column, cursor.location.column + token.kind.description.count)
        }
    }

    func testSuccessfulBooleanParses() throws {
        let location = Location(line: 0, column: 0)

        for (testSource, expectedTokenValue) in [
            ("true ", "true"),
            ("false ", "false"),
        ] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let result = lexKeyword(testSource, cursor)
            guard case .success(let newCursor, let token?) = result else {
                XCTFail("Lexing failed unexpectedly")
                return
            }
            XCTAssertEqual(token.kind, .boolean(expectedTokenValue))
            XCTAssertEqual(newCursor.location.column, cursor.location.column + token.kind.description.count)
        }
    }

    func testFailedKeywordParses() throws {
        let location = Location(line: 0, column: 0)

        for testSource in ["'foo'", "1.23e456", " select", "non-existent"] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let result = lexKeyword(testSource, cursor)
            XCTAssertEqual(result, .failure)
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

            let result = lexIdentifier(testSource, cursor)
            guard case .success(_, let token?) = result else {
                XCTFail("Lexing failed unexpectedly")
                return
            }
            XCTAssertEqual(token.kind, .identifier(expectedTokenValue))
        }
    }

    func testFailedIdentifierParses() throws {
        let location = Location(line: 0, column: 0)

        for testSource in ["\"", "'foo'", "1.23e456", "$foo", "9foo", "_foo"] {
            let cursor = Cursor(pointer: testSource.startIndex, location: location)

            let result = lexIdentifier(testSource, cursor)
            XCTAssertEqual(result, .failure)
        }
    }

    func testSuccessfulLex() throws {
        let source = """
SELECT 'x' FROM foo
WHERE bar = 42;
"""
        let result = lex(source)
        guard case .success(let actualTokens) = result else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        let expectedTokens = [
            Token(kind: .keyword(.select), location: Location(line: 0, column: 0)),
            Token(kind: .string("x"), location: Location(line: 0, column: 7)),
            Token(kind: .keyword(.from), location: Location(line: 0, column: 11)),
            Token(kind: .identifier("foo"), location: Location(line: 0, column: 16)),
            Token(kind: .keyword(.where), location: Location(line: 1, column: 0)),
            Token(kind: .identifier("bar"), location: Location(line: 1, column: 6)),
            Token(kind: .symbol(.equals), location: Location(line: 1, column: 10)),
            Token(kind: .numeric("42"), location: Location(line: 1, column: 12)),
            Token(kind: .symbol(.semicolon), location: Location(line: 1, column: 14)),
        ]
        XCTAssertEqual(actualTokens, expectedTokens)
    }

    func testFailedLex() throws {
        let source = "SELECT 'foo FROM bar;"
        let result = lex(source)
        guard case .failure(let actualErrorMessage) = result else {
            XCTFail("Lexing succeeded unexpectedly")
            return
        }

        let expectedErrorMessage = "Unable to lex token after select, at line 0, column 7"
        XCTAssertEqual(actualErrorMessage, expectedErrorMessage)
    }
}
