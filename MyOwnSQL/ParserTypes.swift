//
//  ParserTypes.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/1/23.
//

enum Expression: Equatable {
    case literal(Token)
}

struct SelectItem: Equatable {
    var expression: Expression
    var alias: String?

    init(_ expression: Expression) {
        self.expression = expression
    }

    init(_ expression: Expression, _ alias: String) {
        self.expression = expression
        self.alias = alias
    }
}

enum Definition: Equatable {
    case column(Token, Token)
}

struct CreateStatement: Equatable {
    var table: Token
    var columns: [Definition]

    init(_ table: Token, _ columns: [Definition]) {
        self.table = table
        self.columns = columns
    }
}

struct SelectStatement: Equatable {
    var table: Token
    var items: [SelectItem]

    init(_ table: Token, _ items: [SelectItem]) {
        self.table = table
        self.items = items
    }
}

struct InsertStatement: Equatable {
    var table: Token
    var items: [Expression]

    init(_ table: Token, _ items: [Expression]) {
        self.table = table
        self.items = items
    }
}

enum Statement: Equatable {
    case create(CreateStatement)
    case insert(InsertStatement)
    case select(SelectStatement)
}
