//
//  ASTTypes.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/1/23.
//

enum Expression: Equatable {
    case literal(Token)
}

enum Definition: Equatable {
    case column(Token, Token)
}

protocol Statement {
}

struct CreateStatement: Statement, Equatable {
    var table: Token
    var columns: [Definition]

    init(_ table: Token, _ columns: [Definition]) {
        self.table = table
        self.columns = columns
    }
}

struct SelectStatement: Statement, Equatable {
    var table: Token
    var items: [Expression]

    init(_ table: Token, _ items: [Expression]) {
        self.table = table
        self.items = items
    }
}

struct InsertStatement: Statement {
    var table: Token
    var items: [Expression]
}

struct AST {
    var statements: [Statement]
}
