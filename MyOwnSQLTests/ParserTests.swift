//
//  ParserTests.swift
//  MyOwnSQLTests
//
//  Created by Danielle Kefford on 2/5/23.
//

import XCTest

class ParserTests: XCTestCase {
    func testSuccessfulParseOfSelectStatement() throws {
        let source = "SELECT 42, 'x', true, foo FROM bar"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .select(let statement)) = parseSelectStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        let expectedStatement = SelectStatement(
            Token(kind: .identifier("bar"), location: Location(line: 0, column: 31)),
            [
                .literal(Token(kind: .numeric("42"), location: Location(line: 0, column: 7))),
                .literal(Token(kind: .string("x"), location: Location(line: 0, column: 11))),
                .literal(Token(kind: .boolean("true"), location: Location(line: 0, column: 16))),
                .literal(Token(kind: .identifier("foo"), location: Location(line: 0, column: 22))),
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testSuccessfulParseOfCreateStatement() throws {
        let source = "CREATE TABLE foo (bar int, baz text, quux boolean)"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .create(let statement)) = parseCreateStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
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
        XCTAssertEqual(statement, expectedStatement)
    }

    func testSuccessfulParseOfInsertStatement() throws {
        let source = "INSERT INTO foo VALUES (42, 'x', false)"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .insert(let statement)) = parseInsertStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        let expectedStatement = InsertStatement(
            Token(kind: .identifier("foo"), location: Location(line: 0, column: 12)),
            [
                .literal(Token(kind: .numeric("42"), location: Location(line: 0, column: 24))),
                .literal(Token(kind: .string("x"), location: Location(line: 0, column: 28))),
                .literal(Token(kind: .boolean("false"), location: Location(line: 0, column: 33))),
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testParseStatement() throws {
        let source = "SELECT 42, 'x', true, foo FROM bar;"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(let cursor, .select) = parseStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        XCTAssertEqual(cursor, 10)
    }

    func testParse() throws {
        let source = "SELECT 42, 'x', true, foo FROM bar;"
        guard case .success(let actualStatements) = parse(source) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        let expectedStatements: [Statement] = [
            .select(
                SelectStatement(
                    Token(kind: .identifier("bar"), location: Location(line: 0, column: 31)),
                    [
                        .literal(Token(kind: .numeric("42"), location: Location(line: 0, column: 7))),
                        .literal(Token(kind: .string("x"), location: Location(line: 0, column: 11))),
                        .literal(Token(kind: .boolean("true"), location: Location(line: 0, column: 16))),
                        .literal(Token(kind: .identifier("foo"), location: Location(line: 0, column: 22))),
                    ]
                )
            ),
        ]
        XCTAssertEqual(actualStatements, expectedStatements)
    }
}
