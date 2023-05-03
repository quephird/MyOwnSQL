//
//  ParserTypes.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/1/23.
//

indirect enum Expression: Equatable {
    case term(Token)
    case unary(Expression, [Token])
    case binary(Expression, Expression, Token)
}

enum SelectItem: Equatable {
    case expression(Expression)
    case expressionWithAlias(Expression, Token)
    case star
}

enum Definition: Equatable {
    case implicitlyNullableColumn(Token, Token)
    case explicitlyNullableColumn(Token, Token, Token)
    case notNullableColumn(Token, Token, [Token])
}

extension Definition {
    var nameToken: Token {
        switch self {
        case .implicitlyNullableColumn(let nameToken, _):
            return nameToken
        case .explicitlyNullableColumn(let nameToken, _, _):
            return nameToken
        case .notNullableColumn(let nameToken, _, _):
            return nameToken
        }
    }

    var typeToken: Token {
        switch self {
        case .implicitlyNullableColumn(_, let typeToken):
            return typeToken
        case .explicitlyNullableColumn(_, let typeToken, _):
            return typeToken
        case .notNullableColumn(_, let typeToken, _):
            return typeToken
        }
    }

    var isNullable: Bool {
        switch self {
        case .implicitlyNullableColumn(_, _):
            return true
        case .explicitlyNullableColumn(_, _, _):
            return true
        case .notNullableColumn(_, _, _):
            return false
        }
    }
}

struct CreateStatement: Equatable {
    var table: Token
    var columns: [Definition]

    init(_ table: Token, _ columns: [Definition]) {
        self.table = table
        self.columns = columns
    }
}

struct OrderByClause: Equatable {
    var items: [Expression]

    init(_ items: [Expression]) {
        self.items = items
    }
}

struct SelectStatement: Equatable {
    var table: Token
    var items: [SelectItem]
    var whereClause: Expression? = nil
    var orderByClause: OrderByClause? = nil

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
    var tuples: [[Expression]]

    init(_ table: Token, _ tuples: [[Expression]]) {
        self.table = table
        self.tuples = tuples
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

struct ColumnAssignment: Equatable {
    var column: Token
    var expression: Expression

    init(_ column: Token, _ expression: Expression) {
        self.column = column
        self.expression = expression
    }
}

struct UpdateStatement: Equatable {
    var table: Token
    var whereClause: Expression? = nil
    var columnAssignments: [ColumnAssignment]

    init(_ table: Token, _ columnAssignments: [ColumnAssignment]) {
        self.table = table
        self.columnAssignments = columnAssignments
    }

    init(_ table: Token, _ columnAssignments: [ColumnAssignment], _ whereClause: Expression) {
        self.table = table
        self.columnAssignments = columnAssignments
        self.whereClause = whereClause
    }
}

enum Statement {
    case create(CreateStatement)
    case insert(InsertStatement)
    case select(SelectStatement)
    case delete(DeleteStatement)
    case update(UpdateStatement)
}
