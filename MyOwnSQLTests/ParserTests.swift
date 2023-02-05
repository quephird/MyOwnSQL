//
//  ParserTests.swift
//  MyOwnSQLTests
//
//  Created by Danielle Kefford on 2/5/23.
//

import XCTest

class ParserTests: XCTestCase {
    func testSuccessfulParseOfSelectStatement() throws {
        let source = """
SELECT 42, 'x', foo FROM bar
"""
        let (actualTokens, _) = lex(source)
        let (maybeStatement, tokenCursor, parsed) = parseSelectStatement(actualTokens!, 0)
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
}
