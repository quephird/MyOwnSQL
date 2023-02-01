//
//  LexerTypes.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 1/5/23.
//

struct Location: Equatable {
    var line: Int
    var column: Int
}

enum Keyword: String, CaseIterable {
    case select = "select"
    case insert = "insert"
    case values = "values"
    case table = "table"
    case create = "create"
    case `where` = "where"
    case from = "from"
    case into = "into"
    case text = "text"
}

enum Symbol: String, CaseIterable {
    case semicolon = ";"
    case asterisk = "*"
    case comma = ","
    case leftParenthesis = "("
    case rightParenthesis = ")"
    case equals = "="
}

enum TokenKind {
    case keyword
    case symbol
    case identifier
    case string
    case numeric
}

struct Token: Equatable {
    var value: String
    var kind: TokenKind
    var location: Location
}

struct Cursor {
    var pointer: String.Index
    var location: Location
}

typealias Lexer = (String, Cursor) -> (Token?, Cursor, Bool)
