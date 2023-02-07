//
//  ParserTests.swift
//  MyOwnSQLTests
//
//  Created by Danielle Kefford on 2/5/23.
//

import XCTest

class ParserTests: XCTestCase {
    func testSuccessfulParseOfSelectStatement() throws {
        let source = "SELECT 42, 'x', foo FROM bar"
        let (actualTokens, _) = lex(source)
        let (maybeStatement, _, _) = parseSelectStatement(actualTokens!, 0)
        let expectedStatement = SelectStatement(
            Token(kind: .identifier("bar"), location: Location(line: 0, column: 25)),
            [
                .literal(Token(kind: .numeric("42"), location: Location(line: 0, column: 7))),
                .literal(Token(kind: .string("x"), location: Location(line: 0, column: 11))),
                .literal(Token(kind: .identifier("foo"), location: Location(line: 0, column: 16))),
            ]
        )
        XCTAssertEqual(maybeStatement!, expectedStatement)
    }

    func testSuccessfulParseOfCreateStatement() throws {
        let source = "CREATE TABLE foo (bar int, baz text, quux boolean)"
        let (actualTokens, _) = lex(source)
        let (maybeStatement, _, _) = parseCreateStatement(actualTokens!, 0)
        let expectedStatement = CreateStatement(
            Token(kind: .identifier("foo"), location: Location(line: 0, column: 13)),
            [
                .column(Token(kind: .identifier("bar"), location: Location(line: 0, column: 18)),
                        Token(kind: .keyword(Keyword(rawValue: "int")!), location: Location(line: 0, column: 22))),
                .column(Token(kind: .identifier("baz"), location: Location(line: 0, column: 27)),
                        Token(kind: .keyword(Keyword(rawValue: "text")!), location: Location(line: 0, column: 31))),
                .column(Token(kind: .identifier("quux"), location: Location(line: 0, column: 37)),
                        Token(kind: .keyword(Keyword(rawValue: "boolean")!), location: Location(line: 0, column: 42))),
            ]
        )
        XCTAssertEqual(maybeStatement!, expectedStatement)
    }

    func testSuccessfulParseOfInsertStatement() throws {
        let source = "INSERT INTO foo VALUES (42, 'x')"
        let (actualTokens, _) = lex(source)
        let (maybeStatement, _, _) = parseInsertStatement(actualTokens!, 0)
        let expectedStatement = InsertStatement(
            Token(kind: .identifier("foo"), location: Location(line: 0, column: 12)),
            [
                .literal(Token(kind: .numeric("42"), location: Location(line: 0, column: 24))),
                .literal(Token(kind: .string("x"), location: Location(line: 0, column: 28))),
            ]
        )
        XCTAssertEqual(maybeStatement!, expectedStatement)
    }
}
