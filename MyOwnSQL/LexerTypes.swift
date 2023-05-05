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
    case create = "create"
    case insert = "insert"
    case select = "select"
    case delete = "delete"
    case update = "update"
    case set = "set"
    case values = "values"
    case table = "table"
    case `where` = "where"
    case from = "from"
    case into = "into"
    case text = "text"
    case int = "int"
    case boolean = "boolean"
    case `true` = "true"
    case `false` = "false"
    case `as` = "as"
    case and = "and"
    case or = "or"
    case not = "not"
    case null = "null"
    case `is` = "is"
    case order = "order"
    case by = "by"
    case asc = "asc"
    case desc = "desc"
}

enum Symbol: String, CaseIterable {
    case semicolon = ";"
    case asterisk = "*"
    case plus = "+"
    case comma = ","
    case leftParenthesis = "("
    case rightParenthesis = ")"
    case equals = "="
    case notEquals = "!="
    case concatenate = "||"
}

enum TokenKind: Hashable, CustomStringConvertible {
    case keyword(Keyword)
    case symbol(Symbol)
    case identifier(String)
    case string(String)
    case numeric(String)
    case boolean(String)

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
        case .boolean(let boolean):
            return boolean
        }
    }
}

struct Token: Equatable {
    var kind: TokenKind
    var location: Location
}

struct Cursor: Equatable {
    var pointer: String.Index
    var location: Location
}
