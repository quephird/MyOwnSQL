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

struct DropTableStatement: Equatable {
    var table: Token

    init(_ table: Token) {
        self.table = table
    }
}

struct OrderByItem: Equatable {
    var expression: Expression
    var sortOrder: Token?

    init(_ expression: Expression) {
        self.expression = expression
    }

    init(_ expression: Expression, _ sortOrder: Token) {
        self.expression = expression
        self.sortOrder = sortOrder
    }
}

struct OrderByClause: Equatable {
    var items: [OrderByItem]

    init(_ items: [OrderByItem]) {
        self.items = items
    }
}

struct SelectedTable: Equatable {
    var name: Token
    var alias: Token?

    init(_ name: Token) {
        self.name = name
    }

    init(_ name: Token, _ alias: Token) {
        self.name = name
        self.alias = alias
    }
}

struct Join: Equatable {
    var table: SelectedTable
    var conditions: Expression?
}

struct SelectStatement: Equatable {
    var table: SelectedTable
    var items: [SelectItem]
    var joins: [Join] = []
    var whereClause: Expression? = nil
    var orderByClause: OrderByClause? = nil

    init(_ table: SelectedTable, _ items: [SelectItem]) {
        self.table = table
        self.items = items
    }

    init(_ table: SelectedTable, _ items: [SelectItem], _ whereClause: Expression) {
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
    case dropTable(DropTableStatement)
    case insert(InsertStatement)
    case select(SelectStatement)
    case delete(DeleteStatement)
    case update(UpdateStatement)
}
