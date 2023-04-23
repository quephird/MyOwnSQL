//
//  ParserTypes.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/1/23.
//

indirect enum Expression: Equatable {
    case term(Token)
    case binary(Expression, Expression, Token)
}

enum SelectItem: Equatable {
    case expression(Expression)
    case expressionWithAlias(Expression, Token)
    case star
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
    var whereClause: Expression? = nil

    init(_ table: Token, _ items: [SelectItem]) {
        self.table = table
        self.items = items
    }

    init(_ table: Token, _ items: [SelectItem], _ whereClause: Expression) {
        self.table = table
        self.items = items
        self.whereClause = whereClause
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

struct DeleteStatement: Equatable {
    var table: Token
    var whereClause: Expression? = nil

    init(_ table: Token) {
        self.table = table
    }

    init(_ table: Token, _ whereClause: Expression) {
        self.table = table
        self.whereClause = whereClause
    }
}

enum Statement: Equatable {
    case create(CreateStatement)
    case insert(InsertStatement)
    case select(SelectStatement)
    case delete(DeleteStatement)
}
