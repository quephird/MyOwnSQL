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

struct Column: Equatable {
    var name: String
    var type: ColumnType

    init(_ name: String, _ type: ColumnType) {
        self.name = name
        self.type = type
    }
}

struct ResultSet: Equatable {
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

enum TypeCheckResult {
    case success(ColumnType)
    case failure(StatementError)
}

enum StatementExecutionResult: Equatable {
    case successfulCreateTable
    case successfulInsert(Int)
    case successfulSelect(ResultSet)
    case failure(StatementError)
}

class MemoryBackend {
    var tables: [String: Table] = [:]

    func executeStatements(_ input: String) -> [StatementExecutionResult] {
        var results: [StatementExecutionResult] = []

        switch parse(input) {
        case .failure(let errorMessage):
            print(errorMessage)
        case .success(let statements):
            for statement in statements {
                switch statement {
                case .create(let createStatement):
                    results.append(createTable(createStatement))
                case .insert(let insertStatement):
                    results.append(insertTable(insertStatement))
                case .select(let selectStatement):
                    results.append(selectTable(selectStatement))
                case .delete:
                    // TODO: Implement handler!!!
                    continue
                }
            }
        }

        return results
    }

    func createTable(_ create: CreateStatement) -> StatementExecutionResult {
        guard case .identifier(let tableName) = create.table.kind else {
            return .failure(.misc("Invalid token for table name"))
        }
        if self.tables[tableName] != nil {
            return .failure(.tableAlreadyExists(tableName))
        }

        var columnNames: [String] = []
        var columnTypes: [ColumnType] = []
        for case .column(let nameToken, let typeToken) in create.columns {
            switch nameToken.kind {
            case .identifier(let name):
                columnNames.append(name)
            default:
                return .failure(.misc("Invalid token for column name"))
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
                    return .failure(.misc("Unsupported column type"))
                }
            default:
                return .failure(.misc("Invalid token for column type"))
            }
        }

        let newTable = Table(columnNames, columnTypes)
        self.tables[tableName] = newTable
        return .successfulCreateTable
    }

    func insertTable(_ insert: InsertStatement) -> StatementExecutionResult {
        switch insert.table.kind {
        case .identifier(let tableName):
            if let table = self.tables[tableName] {
                if insert.items.count < table.columnNames.count {
                    return .failure(.notEnoughValues)
                } else if insert.items.count > table.columnNames.count {
                    return .failure(.tooManyValues)
                }

                var newRow: [MemoryCell] = []
                for item in insert.items {
                    switch item {
                    case .term(let token):
                        if let newCell = makeMemoryCell(token) {
                            newRow.append(newCell)
                        } else {
                            return .failure(.misc("Unable to create cell value from token"))
                        }
                    default:
                        return .failure(.misc("Unable able to handle this kind of expression"))
                    }
                }

                table.data.append(newRow)
                return .successfulInsert(1)
            } else {
                return .failure(.tableDoesNotExist(tableName))
            }
        default:
            return .failure(.misc("Invalid token for table name"))
        }
    }

    func selectTable(_ select: SelectStatement) -> StatementExecutionResult {
        var columns: [Column] = []
        var resultRows: [[MemoryCell]] = []

        guard case .identifier(let tableName) = select.table.kind else {
            return .failure(.misc("Invalid token for table name"))
        }
        guard let table = self.tables[tableName] else {
            return .failure(.tableDoesNotExist(tableName))
        }

        for item in select.items {
            switch item {
            case .expression(let expression):
                if case .failure(let error) = typeCheck(expression, table) {
                    return .failure(error)
                }
            case .expressionWithAlias(let expression, _):
                if case .failure(let error) = typeCheck(expression, table) {
                    return .failure(error)
                }
            case .star:
                continue
            }
        }

        if let whereClause = select.whereClause {
            switch typeCheck(whereClause, table) {
            case .failure(let error):
                return .failure(error)
            case .success(let type):
                if type != .boolean {
                    return .failure(.whereClauseNotBooleanExpression)
                }
            }
        }

        var isFirstRow = true
        for tableRow in table.data {
            var resultRow: [MemoryCell] = []

            if let whereClause = select.whereClause {
                if case .booleanValue(let keepRow) = evaluateExpression(whereClause, table, tableRow), !keepRow {
                    continue
                }
            }

            for (i, item) in select.items.enumerated() {
                switch item {
                case .expression(let expression):
                    guard let value = evaluateExpression(expression, table, tableRow) else {
                        return .failure(.misc("Unable to evaluate expression in SELECT"))
                    }

                    if isFirstRow {
                        if case .term(let token) = expression, case .identifier(let requestedColumnName) = token.kind {
                            for (i, columnName) in table.columnNames.enumerated() {
                                if requestedColumnName == columnName {
                                    columns.append(Column(columnName, table.columnTypes[i]))
                                    break
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
                        return .failure(.misc("Unable to evaulate expression"))
                    }

                    if isFirstRow {
                        guard case .identifier(let alias) = aliasToken.kind else {
                            return .failure(.misc("Bad alias token encountered"))
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
        return .successfulSelect(ResultSet(columns, resultRows))
    }

    func typeCheck(_ expression: Expression, _ table: Table) -> TypeCheckResult {
        switch expression {
        case .term(let token):
            switch token.kind {
            case .boolean:
                return .success(.boolean)
            case .numeric:
                // TODO: We need to support doubles at some point
                return .success(.int)
            case .string:
                return .success(.text)
            case .identifier(let requestedColumnName):
                for (i, columnName) in table.columnNames.enumerated() {
                    if requestedColumnName == columnName {
                        return .success(table.columnTypes[i])
                    }
                }
                return .failure(StatementError.columnDoesNotExist(requestedColumnName))
            default:
                return .failure(StatementError.invalidExpression)
            }
        case .binary(let leftExpr, let rightExpr, let operatorToken):
            var leftType: ColumnType
            switch typeCheck(leftExpr, table) {
            case .failure(let error):
                return .failure(error)
            case .success(let type):
                leftType = type
            }

            var rightType: ColumnType
            switch typeCheck(rightExpr, table) {
            case .failure(let error):
                return .failure(error)
            case .success(let type):
                rightType = type
            }

            switch operatorToken.kind {
            case .keyword(.and), .keyword(.or):
                if leftType == .boolean && rightType == .boolean {
                    return .success(.boolean)
                } else {
                    return .failure(StatementError.invalidExpression)
                }
            case .symbol(.equals), .symbol(.notEquals):
                if leftType == rightType {
                    return .success(.boolean)
                } else {
                    return .failure(StatementError.invalidExpression)
                }
            case .symbol(.plus), .symbol(.asterisk):
                if leftType == .int && rightType == .int {
                    return .success(.int)
                } else {
                    return .failure(StatementError.invalidExpression)
                }
            case .symbol(.concatenate):
                if leftType == .text && rightType == .text {
                    return .success(.text)
                } else {
                    return .failure(StatementError.invalidExpression)
                }
            default:
                return .failure(StatementError.invalidExpression)
            }
        }
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
