//
//  Memory.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/7/23.
//

enum MemoryCell: Equatable {
    case intValue(Int)
    case textValue(String)
    case booleanValue(Bool)
}

enum ColumnType {
    case int
    case text
    case boolean
}

struct Column {
    var name: String
    var type: ColumnType

    init(_ name: String, _ type: ColumnType) {
        self.name = name
        self.type = type
    }
}

struct ResultSet {
    var columns: [Column]
    var rows: [[MemoryCell]]

    init(_ columns: [Column], _ rows: [[MemoryCell]]) {
        self.columns = columns
        self.rows = rows
    }
}

class Table {
    // TODO: Look into OrderedDictionary in swift-collections library
    var columnNames: [String]
    var columnTypes: [ColumnType]
    var data: [[MemoryCell]]

    init(_ columnNames: [String], _ columnTypes: [ColumnType]) {
        self.columnNames = columnNames
        self.columnTypes = columnTypes
        self.data = []
    }
}

class MemoryBackend {
    var tables: [String: Table] = [:]

    func createTable(_ create: CreateStatement) throws {
        guard case .identifier(let tableName) = create.table.kind else {
            throw StatementError.misc("Invalid token for table name")
        }
        if self.tables[tableName] != nil {
            throw StatementError.tableAlreadyExists(tableName)
        }

        var columnNames: [String] = []
        var columnTypes: [ColumnType] = []
        for case .column(let nameToken, let typeToken) in create.columns {
            switch nameToken.kind {
            case .identifier(let name):
                columnNames.append(name)
            default:
                throw StatementError.misc("Invalid token for column name")
            }

            switch typeToken.kind {
            case .keyword(let keyword):
                switch keyword {
                case .text:
                    columnTypes.append(.text)
                case .int:
                    columnTypes.append(.int)
                case .boolean:
                    columnTypes.append(.boolean)
                default:
                    throw StatementError.misc("Invalid column type")
                }
            default:
                throw StatementError.misc("Invalid token for column type")
            }
        }

        let newTable = Table(columnNames, columnTypes)
        self.tables[tableName] = newTable
    }

    func insertTable(_ insert: InsertStatement) throws {
        switch insert.table.kind {
        case .identifier(let tableName):
            if let table = self.tables[tableName] {
                if insert.items.count < table.columnNames.count {
                    throw StatementError.notEnoughValues
                } else if insert.items.count > table.columnNames.count {
                    throw StatementError.tooManyValues
                }

                var newRow: [MemoryCell] = []
                for item in insert.items {
                    switch item {
                    case .term(let token):
                        if let newCell = makeMemoryCell(token) {
                            newRow.append(newCell)
                        } else {
                            throw StatementError.misc("Unable to create cell value from token")
                        }
                    default:
                        throw StatementError.misc("Unable able to handle this kind of expression")
                    }
                }

                table.data.append(newRow)
                return
            } else {
                throw StatementError.tableDoesNotExist(tableName)
            }
        default:
            throw StatementError.misc("Invalid token for table name")
        }
    }

    func selectTable(_ select: SelectStatement) throws -> ResultSet {
        var columns: [Column] = []
        var resultRows: [[MemoryCell]] = []

        guard case .identifier(let tableName) = select.table.kind else {
            throw StatementError.misc("Invalid token for table name")
        }
        guard let table = self.tables[tableName] else {
            throw StatementError.tableDoesNotExist(tableName)
        }

        var isFirstRow = true
        for tableRow in table.data {
            var resultRow: [MemoryCell] = []

            if let whereClause = select.whereClause {
                guard let value = evaluateExpression(whereClause, table, tableRow) else {
                    throw StatementError.misc("Unable to evaulate expression in WHERE clause")
                }

                // TODO: Need to move this logic to just after the parsing stage (static analysis)
                switch value {
                case .booleanValue(let booleanValue):
                    if !booleanValue {
                        continue
                    }
                default:
                    throw StatementError.misc("WHERE clause is not a boolean expression")
                }
            }

            for (i, item) in select.items.enumerated() {
                switch item {
                case .expression(let expression):
                    guard let value = evaluateExpression(expression, table, tableRow) else {
                        throw StatementError.misc("Unable to evaulate expression in SELECT")
                    }

                    if isFirstRow {
                        if case .term(let token) = expression, case .identifier(let requestedColumnName) = token.kind {
                            if !table.columnNames.contains(requestedColumnName) {
                                throw StatementError.columnDoesNotExist(requestedColumnName)
                            } else {
                                for (i, columnName) in table.columnNames.enumerated() {
                                    if requestedColumnName == columnName {
                                        columns.append(Column(columnName, table.columnTypes[i]))
                                        break
                                    }
                                }
                            }
                        } else {
                            switch value {
                            case .intValue:
                                columns.append(Column("col_\(i)", .int))
                            case .textValue:
                                columns.append(Column("col_\(i)", .text))
                            case .booleanValue:
                                columns.append(Column("col_\(i)", .boolean))
                            }
                        }
                    }

                    resultRow.append(value)
                case .expressionWithAlias(let expression, let aliasToken):
                    guard let value = evaluateExpression(expression, table, tableRow) else {
                        throw StatementError.misc("Unable to evaulate expression")
                    }

                    if isFirstRow {
                        guard case .identifier(let alias) = aliasToken.kind else {
                            throw StatementError.misc("Bad alias token encountered")
                        }

                        switch value {
                        case .intValue:
                            columns.append(Column(alias, .int))
                        case .textValue:
                            columns.append(Column(alias, .text))
                        case .booleanValue:
                            columns.append(Column(alias, .boolean))
                        }
                    }

                    resultRow.append(value)
                case .star:
                    if isFirstRow {
                        for (i, columnName) in table.columnNames.enumerated() {
                            columns.append(Column(columnName, table.columnTypes[i]))
                        }
                    }
                    for (i, _) in table.columnNames.enumerated() {
                        resultRow.append(tableRow[i])
                    }
                }
            }
            isFirstRow = false
            resultRows.append(resultRow)
        }
        return ResultSet(columns, resultRows)
    }
}

func evaluateExpression(_ expr: Expression, _ table: Table, _ tableRow: [MemoryCell]) -> MemoryCell? {
    switch expr {
    case .term(let token):
        switch token.kind {
        case .string(let value):
            return .textValue(value)
        case .numeric(let value):
            // TODO: Here is where we should endeavor to try
            //       to create a float value if we can't create
            //       an int
            if let value = Int(value) {
                return .intValue(value)
            } else {
                // TODO: What should this return to indicate a problem?
                return nil
            }
        case .boolean(let value):
            switch value {
            case "true":
                return .booleanValue(true)
            default:
                return .booleanValue(false)
            }
        case .identifier(let requestedColumnName):
            for (i, columnName) in table.columnNames.enumerated() {
                if requestedColumnName == columnName {
                    return tableRow[i]
                }
            }
            return nil
        default:
            return nil
        }
    case .binary(let leftExpr, let rightExpr, let operatorToken):
        guard let leftValue = evaluateExpression(leftExpr, table, tableRow) else {
            return nil
        }

        guard let rightValue = evaluateExpression(rightExpr, table, tableRow) else {
            return nil
        }

        switch operatorToken.kind {
        case .keyword(.and):
            switch (leftValue, rightValue) {
            case (.booleanValue(let leftBool), .booleanValue(let rightBool)):
                return .booleanValue(leftBool && rightBool)
            default:
                return nil
            }
        case .keyword(.or):
            switch (leftValue, rightValue) {
            case (.booleanValue(let leftBool), .booleanValue(let rightBool)):
                return .booleanValue(leftBool || rightBool)
            default:
                return nil
            }
        case .symbol(.plus):
            switch (leftValue, rightValue) {
            case (.intValue(let leftInt), .intValue(let rightInt)):
                return .intValue(leftInt + rightInt)
            default:
                return nil
            }
        case .symbol(.asterisk):
            switch (leftValue, rightValue) {
            case (.intValue(let leftInt), .intValue(let rightInt)):
                return .intValue(leftInt * rightInt)
            default:
                return nil
            }
        case .symbol(.concatenate):
            switch (leftValue, rightValue) {
            case (.textValue(let leftText), .textValue(let rightText)):
                return .textValue(leftText + rightText)
            default:
                return nil
            }
        case .symbol(.equals):
            switch (leftValue, rightValue) {
            case (.booleanValue(let leftBool), .booleanValue(let rightBool)):
                return .booleanValue(leftBool == rightBool)
            case (.intValue(let leftInt), .intValue(let rightInt)):
                return .booleanValue(leftInt == rightInt)
            case (.textValue(let leftText), .textValue(let rightText)):
                return .booleanValue(leftText == rightText)
            default:
                return nil
            }
        case .symbol(.notEquals):
            switch (leftValue, rightValue) {
            case (.booleanValue(let leftBool), .booleanValue(let rightBool)):
                return .booleanValue(leftBool != rightBool)
            case (.intValue(let leftInt), .intValue(let rightInt)):
                return .booleanValue(leftInt != rightInt)
            case (.textValue(let leftText), .textValue(let rightText)):
                return .booleanValue(leftText != rightText)
            default:
                return nil
            }
        default:
            return nil
        }
    }
}

func makeMemoryCell(_ token: Token) -> MemoryCell? {
    switch token.kind {
    case .string(let value):
        return .textValue(value)
    case .numeric(let value):
        // TODO: Here is where we should endeavor to try
        //       to create a float value if we can't create
        //       an int
        if let value = Int(value) {
            return .intValue(value)
        } else {
            // TODO: What should this return to indicate a problem?
            return nil
        }
    case .boolean(let value):
        switch value {
        case "true":
            return .booleanValue(true)
        default:
            return .booleanValue(false)
        }
    default:
        return nil
    }
}
