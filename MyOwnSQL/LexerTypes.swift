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

enum TokenKind: Hashable, CustomStringConvertible {
    case keyword(Keyword)
    case symbol(Symbol)
    case identifier(String)
    case string(String)
    case numeric(String)

    var description: String {
        switch self {
        case .keyword(let keyword):
            return keyword.rawValue
        case .symbol(let symbol):
            return symbol.rawValue
        case .identifier(let identifier):
            return "\"" + identifier + "\""
        case .string(let string):
            return "\'" + string + "\'"
        case .numeric(let numeric):
            return numeric
        }
    }
}

struct Token: Equatable {
    var kind: TokenKind
    var location: Location
}

struct Cursor {
    var pointer: String.Index
    var location: Location
}
