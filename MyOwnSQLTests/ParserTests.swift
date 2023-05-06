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

    func testSelectWithUnaryExpression() throws {
        let source = "SELECT foo FROM bar WHERE baz IS NOT NULL"
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
            .unary(
                .term(Token(kind: .identifier("baz"), location: Location(line: 0, column: 26))),
                [
                    Token(kind: .keyword(.is), location: Location(line: 0, column: 30)),
                    Token(kind: .keyword(.not), location: Location(line: 0, column: 33)),
                    Token(kind: .keyword(.null), location: Location(line: 0, column: 37)),
                ]
            )
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testSelectWithUnaryExpressionInsideBinaryExpression() throws {
        let source = "SELECT foo FROM bar WHERE baz IS NOT NULL AND quux = 42"
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
                .unary(
                    .term(Token(kind: .identifier("baz"), location: Location(line: 0, column: 26))),
                    [
                        Token(kind: .keyword(.is), location: Location(line: 0, column: 30)),
                        Token(kind: .keyword(.not), location: Location(line: 0, column: 33)),
                        Token(kind: .keyword(.null), location: Location(line: 0, column: 37)),
                    ]
                ),
                .binary(
                    .term(Token(kind: .identifier("quux"), location: Location(line: 0, column: 46))),
                    .term(Token(kind: .numeric("42"), location: Location(line: 0, column: 53))),
                    Token(kind: .symbol(.equals), location: Location(line: 0, column: 51))
                ),
                Token(kind: .keyword(.and), location: Location(line: 0, column: 42))
            )
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testSelectWithOrderByClause() throws {
        let source = "SELECT * FROM dresses ORDER BY description, is_fabulous, id"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .select(let statement)) = parseSelectStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        var expectedStatement = SelectStatement(
            Token(kind: .identifier("dresses"), location: Location(line: 0, column: 14)),
            [
                .star
            ]
        )
        expectedStatement.orderByClause = OrderByClause([
            OrderByItem(
                .term(Token(kind: .identifier("description"), location: Location(line: 0, column: 31)))
            ),
            OrderByItem(
                .term(Token(kind: .identifier("is_fabulous"), location: Location(line: 0, column: 44)))
            ),
            OrderByItem(
                .term(Token(kind: .identifier("id"), location: Location(line: 0, column: 57)))
            ),
        ])

        XCTAssertEqual(statement, expectedStatement)
    }

    func testSelectWithOrderByClauseWithExplicitAscAndDesc() throws {
        let source = "SELECT * FROM dresses ORDER BY description ASC, id DESC"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }
        guard case .success(_, .select(let statement)) = parseSelectStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        var expectedStatement = SelectStatement(
            Token(kind: .identifier("dresses"), location: Location(line: 0, column: 14)),
            [
                .star
            ]
        )
        expectedStatement.orderByClause = OrderByClause([
            OrderByItem(
                .term(Token(kind: .identifier("description"), location: Location(line: 0, column: 31))),
                Token(kind: .keyword(.asc), location: Location(line: 0, column: 43))
            ),
            OrderByItem(
                .term(Token(kind: .identifier("id"), location: Location(line: 0, column: 48))),
                Token(kind: .keyword(.desc), location: Location(line: 0, column: 51))
            ),
        ])

        XCTAssertEqual(statement, expectedStatement)
    }

    func testInvalidSelectStatementsShouldFailToParse() throws {
        for source in [
            "SELECT FROM bar", // No select items
            "SELECT 42 foo", // Missing FROM keyword
            "SELECT 42 FROM", // Missing table name
            "SELECT 42 'forty-two' FROM foo", // Missing comma between two items
            "SELECT 42 AS FROM foo", // Missing select item alias
            "SELECT * AS everything FROM FOO", // Cannot alias the star symbol
            "SELECT * FROM foo WHERE", // No WHERE expression
            "SELECT * FROM foo ORDER BY", // No ORDER BY items
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
                .implicitlyNullableColumn(
                    Token(kind: .identifier("bar"), location: Location(line: 0, column: 18)),
                    Token(kind: .keyword(.int), location: Location(line: 0, column: 22))
                ),
                .implicitlyNullableColumn(
                    Token(kind: .identifier("baz"), location: Location(line: 0, column: 27)),
                    Token(kind: .keyword(.text), location: Location(line: 0, column: 31))
                ),
                .implicitlyNullableColumn(
                    Token(kind: .identifier("quux"), location: Location(line: 0, column: 37)),
                    Token(kind: .keyword(.boolean), location: Location(line: 0, column: 42))
                ),
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testParseCreateStatementWithNullQualifiers() throws {
        let source = "CREATE TABLE foo(bar INT, baz TEXT NULL, quux BOOLEAN NOT NULL)"
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
                .implicitlyNullableColumn(
                    Token(kind: .identifier("bar"), location: Location(line: 0, column: 17)),
                    Token(kind: .keyword(.int), location: Location(line: 0, column: 21))
                ),
                .explicitlyNullableColumn(
                    Token(kind: .identifier("baz"), location: Location(line: 0, column: 26)),
                    Token(kind: .keyword(.text), location: Location(line: 0, column: 30)),
                    Token(kind: .keyword(.null), location: Location(line: 0, column: 35))
                ),
                .notNullableColumn(
                    Token(kind: .identifier("quux"), location: Location(line: 0, column: 41)),
                    Token(kind: .keyword(.boolean), location: Location(line: 0, column: 46)),
                    [
                        Token(kind: .keyword(.not), location: Location(line: 0, column: 54)),
                        Token(kind: .keyword(.null), location: Location(line: 0, column: 58))
                    ]
                ),
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

    func testSuccessfulParseOfDropTableStatement() throws {
        let source = "DROP TABLE foo"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .dropTable(let statement)) = parseDropTableStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        let expectedStatement = DropTableStatement(
            Token(kind: .identifier("foo"), location: Location(line: 0, column: 11))
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testFailedParseOfDropTableStatement() throws {
        let source = "DROP foo"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .failure = parseDropTableStatement(tokens, 0) else {
            XCTFail("Parsing succeeded unexpectedly")
            return
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
                [
                    .term(Token(kind: .numeric("42"), location: Location(line: 0, column: 24))),
                    .term(Token(kind: .string("x"), location: Location(line: 0, column: 28))),
                    .term(Token(kind: .boolean("false"), location: Location(line: 0, column: 33))),
                ],
            ]
        )
        XCTAssertEqual(statement, expectedStatement)
    }

    func testParseInsertStatementWithMultipleTuples() throws {
        let source = "INSERT INTO foo VALUES(1, 'bar'), (2, 'baz'), (3, 'quux')"
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
                [
                    .term(Token(kind: .numeric("1"), location: Location(line: 0, column: 23))),
                    .term(Token(kind: .string("bar"), location: Location(line: 0, column: 26))),
                ],
                [
                    .term(Token(kind: .numeric("2"), location: Location(line: 0, column: 35))),
                    .term(Token(kind: .string("baz"), location: Location(line: 0, column: 38))),
                ],
                [
                    .term(Token(kind: .numeric("3"), location: Location(line: 0, column: 47))),
                    .term(Token(kind: .string("quux"), location: Location(line: 0, column: 50))),
                ],
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

    func testInvalidDeleteStatementsShouldFailToParse() throws {
        for source in [
            "DELETE foo", // Missing FROM keyword
            "DELETE FROM WHERE bar = 1", // Missing table name
            "DELETE FROM foo WHERE", // No expression following WHERE
        ] {
            guard case .success(let tokens) = lex(source) else {
                XCTFail("Lexing failed unexpectedly")
                return
            }

            guard case .failure = parseDeleteStatement(tokens, 0) else {
                XCTFail("Parsing succeeded unexpectedly")
                return
            }
        }
    }

    func testSuccessfulParseOfUpdateStatement() throws {
        let source = "UPDATE foo SET bar = 1, baz = 2 WHERE quux = 3"
        guard case .success(let tokens) = lex(source) else {
            XCTFail("Lexing failed unexpectedly")
            return
        }

        guard case .success(_, .update(let statement)) = parseUpdateStatement(tokens, 0) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }

        let expectedStatement = UpdateStatement(
            Token(kind: .identifier("foo"), location: Location(line: 0, column: 7)),
            [
                ColumnAssignment(
                    Token(kind: .identifier("bar"), location: Location(line: 0, column: 15)),
                    .term(Token(kind: .numeric("1"), location: Location(line: 0, column: 21)))
                ),
                ColumnAssignment(
                    Token(kind: .identifier("baz"), location: Location(line: 0, column: 24)),
                    .term(Token(kind: .numeric("2"), location: Location(line: 0, column: 30)))
                ),
            ],
            .binary(
                .term(Token(kind: .identifier("quux"), location: Location(line: 0, column: 38))),
                .term(Token(kind: .numeric("3"), location: Location(line: 0, column: 45))),
                Token(kind: .symbol(.equals), location: Location(line: 0, column: 43))
            )
        )
         XCTAssertEqual(statement, expectedStatement)
    }

    func testInvalidUpdateStatementsShouldFailToParse() throws {
        for source in [
            "UPDATE SET bar = bar + 1", // Missing table name
            "UPDATE foo SET 1 = 1", // Column assignment missing column name
            "UPDATE foo bar = bar + 1", // Missing SET keyword
            "UPDATE foo SET bar = bar + 1 WHERE", // No expression following WHERE
        ] {
            guard case .success(let tokens) = lex(source) else {
                XCTFail("Lexing failed unexpectedly")
                return
            }

            guard case .failure = parseUpdateStatement(tokens, 0) else {
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
delete from foo where bar = 42;
update foo set bar = bar + 1;
"""

        guard case .success(let statements) = parse(source) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        XCTAssertEqual(statements.count, 5)

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
        guard case .delete = statements[3] else {
            XCTFail("Expected SELECT statement")
            return
        }
        guard case .update = statements[4] else {
            XCTFail("Expected SELECT statement")
            return
        }
    }
}
