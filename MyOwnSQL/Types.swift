//
//  Types.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 1/5/23.
//

struct Location {
    var line: Int
    var column: Int
}

enum Keyword: String {
    case select = "select"
    case from = "from"
    case `as` = "as"
    case table = "table"
    case create = "create"
    case insert = "insert"
    case into = "into"
    case values = "values"
    case int = "int"
    case text = "text"
}

enum Symbol: String {
    case semicolon = ";"
    case asterisk = "*"
    case comma = ","
    case leftParenthesis = "("
    case rightParenthesis = ")"
}

enum TokenKind {
    case keyword
    case symbol
    case identifier
    case string
    case numeric
}

struct Token {
    var value: String
    var kind: TokenKind
    var location: Location

    func equals(_ other: Token) -> Bool {
        return self.value == other.value && self.kind == other.kind
    }
}

struct Cursor {
    var pointer: String.Index
    var location: Location
}

typealias Lexer = (String, Cursor) -> (Token?, Cursor, Bool)
