//
//  ParserTests.swift
//  MyOwnSQLTests
//
//  Created by Danielle Kefford on 2/5/23.
//

import XCTest

class ParserTests: XCTestCase {
    func testParseTermExpression() throws {
        let source = "42"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        let delimiters: [TokenKind] = [.keyword(.from), .keyword(.as), .symbol(.comma)]
        guard case .success(_, let expression) = parseExpression(tokens, 0, delimiters, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        let expectedExpression: Expression = .term(
            Token(
                kind: .numeric("42"),
                location: Location(line: 0, column: 0)
            ))
        XCTAssertEqual(expression, expectedExpression)
    }

    func testParseBinaryExpression() throws {
        let source = "1 + 2"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        let delimiters: [TokenKind] = [.keyword(.from), .keyword(.as), .symbol(.comma)]
        guard case .success(_, let expression) = parseExpression(tokens, 0, delimiters, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        let expectedExpression: Expression = .binary(
            .term(
                Token(
                    kind: .numeric("1"),
                    location: Location(line: 0, column: 0)
                )),
            .term(
                Token(
                    kind: .numeric("2"),
                    location: Location(line: 0, column: 4)
                )),
            Token(
                kind: .symbol(.plus),
                location: Location(line: 0, column: 2)
            ))

        XCTAssertEqual(expression, expectedExpression)
    }

    func testParseComplexBinaryExpression() throws {
        let source = "1 + 2 * 3"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        let delimiters: [TokenKind] = [.keyword(.from), .keyword(.as), .symbol(.comma)]
        guard case .success(_, let expression) = parseExpression(tokens, 0, delimiters, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        let expectedExpression: Expression = .binary(
            .term(
                Token(
                    kind: .numeric("1"),
                    location: Location(line: 0, column: 0)
                )),
            .binary(
                .term(
                    Token(
                        kind: .numeric("2"),
                        location: Location(line: 0, column: 4)
                    )),
                .term(
                    Token(
                        kind: .numeric("3"),
                        location: Location(line: 0, column: 8)
                    )),
                Token(
                    kind: .symbol(.asterisk),
                    location: Location(line: 0, column: 6)
            )),
            Token(
                kind: .symbol(.plus),
                location: Location(line: 0, column: 2)
            ))

        XCTAssertEqual(expression, expectedExpression)
    }

    func testParseComplexBinaryExpressionWithAdditionFollowingMultiplication() throws {
        let source = "1 * 2 + 3"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        let delimiters: [TokenKind] = [.keyword(.from), .keyword(.as), .symbol(.comma)]
        guard case .success(_, let expression) = parseExpression(tokens, 0, delimiters, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        let expectedExpression: Expression = .binary(
            .binary(
                .term(
                    Token(
                        kind: .numeric("1"),
                        location: Location(line: 0, column: 0)
                    )),
                .term(
                    Token(
                        kind: .numeric("2"),
                        location: Location(line: 0, column: 4)
                    )),
                Token(
                    kind: .symbol(.asterisk),
                    location: Location(line: 0, column: 2)
            )),
            .term(
                Token(
                    kind: .numeric("3"),
                    location: Location(line: 0, column: 8)
                )),
            Token(
                kind: .symbol(.plus),
                location: Location(line: 0, column: 6)
            ))

        XCTAssertEqual(expression, expectedExpression)
    }

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
                .expression(.term(Token(kind: .numeric("42"), location: Location(line: 0, column: 7)))),
                .expression(.term(Token(kind: .string("x"), location: Location(line: 0, column: 11)))),
                .expression(.term(Token(kind: .boolean("true"), location: Location(line: 0, column: 16)))),
                .expression(.term(Token(kind: .identifier("foo"), location: Location(line: 0, column: 22)))),
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
                .expressionWithAlias(
                    .term(Token(kind: .string("What is the meaning?"), location: Location(line: 0, column: 7))),
                    Token(kind: .identifier("the_question"), location: Location(line: 0, column: 33))),
                .expressionWithAlias(
                    .term(Token(kind: .numeric("42"), location: Location(line: 0, column: 47))),
                    Token(kind: .identifier("the_answer"), location: Location(line: 0, column: 53))),
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testParseSelectStatementWithStar() throws {
        let source = "SELECT * FROM some_table"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .select(let statement)) = parseSelectStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        let expectedStatement = SelectStatement(
            Token(kind: .identifier("some_table"), location: Location(line: 0, column: 14)),
            [
                .star
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testParseSelectStatementWithWhereClause() throws {
        let source = "SELECT foo FROM bar WHERE baz = 1"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .select(let statement)) = parseSelectStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        let expectedStatement = SelectStatement(
            Token(kind: .identifier("bar"), location: Location(line: 0, column: 16)),
            [
                .expression(.term(Token(kind: .identifier("foo"), location: Location(line: 0, column: 7))))
            ],
            .binary(
                .term(Token(kind: .identifier("baz"), location: Location(line: 0, column: 26))),
                .term(Token(kind: .numeric("1"), location: Location(line: 0, column: 32))),
                Token(kind: .symbol(.equals), location: Location(line: 0, column: 30))
            )
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testInvalidSelectStatementsShouldFailToParse() throws {
        for source in [
            "SELECT FROM bar",
            "SELECT 42 foo",
            "SELECT 42 FROM",
            "SELECT 42 'forty-two' FROM foo",
            "SELECT 42 AS FROM foo",
            "SELECT * AS everything FROM FOO",
            "SELECT * FROM foo WHERE",
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

    func testSuccessfulParseOfSimpleDeleteStatement() throws {
        let source = "DELETE FROM foo"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .delete(let statement)) = parseDeleteStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        let expectedStatement = DeleteStatement(
            Token(kind: .identifier("foo"), location: Location(line: 0, column: 12))
        )
         XCTAssertEqual(statement, expectedStatement)
    }

    func testSuccessfulParseOfDeleteStatementWithWhereClause() throws {
        let source = "DELETE FROM foo WHERE bar = 1"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .delete(let statement)) = parseDeleteStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        let expectedStatement = DeleteStatement(
            Token(kind: .identifier("foo"), location: Location(line: 0, column: 12)),
            .binary(
                .term(Token(kind: .identifier("bar"), location: Location(line: 0, column: 22))),
                .term(Token(kind: .numeric("1"), location: Location(line: 0, column: 28))),
                Token(kind: .symbol(.equals), location: Location(line: 0, column: 26))
            )
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
