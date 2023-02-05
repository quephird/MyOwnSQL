//
//  ASTTypes.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/1/23.
//

protocol Expression {
}

struct LiteralExpression: Expression {
    var literal: Token
}

struct ColumnDefinition {
    var name: Token
    var datatype: Token
}

protocol Statement {
}

struct CreateStatement: Statement {
    var table: Token
    var columns: [ColumnDefinition]
}

struct SelectStatement: Statement {
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
