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
                SelectItem(.term(Token(kind: .numeric("42"), location: Location(line: 0, column: 7)))),
                SelectItem(.term(Token(kind: .string("x"), location: Location(line: 0, column: 11)))),
                SelectItem(.term(Token(kind: .boolean("true"), location: Location(line: 0, column: 16)))),
                SelectItem(.term(Token(kind: .identifier("foo"), location: Location(line: 0, column: 22)))),
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testParseSelectStatementWithAsClause() throws {
        let source = "SELECT 'What is the meaning?' as the_question, 42 as the_answer FROM the_universe"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .select(let statement)) = parseSelectStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        let expectedStatement = SelectStatement(
            Token(kind: .identifier("the_universe"), location: Location(line: 0, column: 69)),
            [
                SelectItem(
                    .term(Token(kind: .string("What is the meaning?"), location: Location(line: 0, column: 7))),
                    Token(kind: .identifier("the_question"), location: Location(line: 0, column: 33))),
                SelectItem(
                    .term(Token(kind: .numeric("42"), location: Location(line: 0, column: 47))),
                    Token(kind: .identifier("the_answer"), location: Location(line: 0, column: 53))),
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testFailedParseOfSelectStatement() throws {
        for source in [
            "SELECT FROM bar",
            "SELECT 42 foo",
            "SELECT 42 FROM",
            "SELECT 42 'forty-two' FROM foo",
        ] {
            guard case .success(let tokens) = lex(source) else {
                XCTFail("Lexing failed unexpectedly")
                return
            }

            guard case .failure = parseSelectStatement(tokens, 0) else {
                XCTFail("Parsing succeeded unexpectedly")
                return
            }
        }
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

    func testFailedParseOfCreateStatement() throws {
        for source in [
            "CREATE foo",
            "CREATE TABLE foo",
            "CREATE TABLE foo bar INT, baz TEXT",
            "CREATE TABLE foo (bar INT baz TEXT)",
            "CREATE TABLE foo (bar INT, baz TEXT",
        ] {
            guard case .success(let tokens) = lex(source) else {
                XCTFail("Lexing failed unexpectedly")
                return
            }

            guard case .failure = parseCreateStatement(tokens, 0) else {
                XCTFail("Parsing succeeded unexpectedly")
                return
            }
        }
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
                .term(Token(kind: .numeric("42"), location: Location(line: 0, column: 24))),
                .term(Token(kind: .string("x"), location: Location(line: 0, column: 28))),
                .term(Token(kind: .boolean("false"), location: Location(line: 0, column: 33))),
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testFailedParseOfInsertStatement() throws {
        for source in [
            "INSERT foo VALUES (42, 'forty-two')",
            "INSERT INTO foo (42, 'forty-two')",
            "INSERT INTO foo VALUES 42, 'forty-two'",
        ] {
            guard case .success(let tokens) = lex(source) else {
                XCTFail("Lexing failed unexpectedly")
                return
            }

            guard case .failure = parseInsertStatement(tokens, 0) else {
                XCTFail("Parsing succeeded unexpectedly")
                return
            }
        }
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
        let source = """
create table foo (bar int);
insert into foo values (42);
select bar from foo;
"""

        guard case .success(let statements) = parse(source) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        XCTAssertEqual(statements.count, 3)

        guard case .create = statements[0] else {
            XCTFail("Expected CREATE statement")
            return
        }
        guard case .insert = statements[1] else {
            XCTFail("Expected INSERT statement")
            return
        }
        guard case .select = statements[2] else {
            XCTFail("Expected SELECT statement")
            return
        }
    }
}
