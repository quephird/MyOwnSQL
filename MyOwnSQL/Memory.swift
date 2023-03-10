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
        // TODO: Think about how to avoid iterating through selected items twice
        for item in select.items {
            if case .expression(.term(let token)) = item {
                switch token.kind {
                case .identifier(let selectedColumnName):
                    if !table.columnNames.contains(selectedColumnName) {
                        throw StatementError.columnDoesNotExist(selectedColumnName)
                    }
                default:
                    continue
                }
            }
        }

        for (rowNumber, tableRow) in table.data.enumerated() {
            var resultRow: [MemoryCell] = []

            // TODO: _Seriously_ need to refactor this for loop
            for (i, item) in select.items.enumerated() {
                switch item {
                case .expression(.term(let token)):
                    switch token.kind {
                    case .boolean:
                        if rowNumber == 0 {
                            let newColumn = Column("col_\(i)", .boolean)
                            columns.append(newColumn)
                        }
                        resultRow.append(makeMemoryCell(token)!)
                    case .numeric:
                        if rowNumber == 0 {
                            let newColumn = Column("col_\(i)", .int)
                            columns.append(newColumn)
                        }
                        resultRow.append(makeMemoryCell(token)!)
                    case .string:
                        if rowNumber == 0 {
                            let newColumn = Column("col_\(i)", .text)
                            columns.append(newColumn)
                        }
                        resultRow.append(makeMemoryCell(token)!)
                    case .identifier(let requestedColumnName):
                        for (i, columnName) in table.columnNames.enumerated() {
                            if requestedColumnName == columnName {
                                if rowNumber == 0 {
                                    let newColumn = Column(requestedColumnName, table.columnTypes[i])
                                    columns.append(newColumn)
                                }
                                resultRow.append(tableRow[i])
                                break
                            }
                        }
                    default:
                        throw StatementError.misc("Unable to handle this kind of token")
                    }
                case .expressionWithAlias(.term(let expressionToken), let aliasToken):
                    guard case .identifier(let alias) = aliasToken.kind else {
                        throw StatementError.misc("Cannot determine alias for expression")
                    }

                    switch expressionToken.kind {
                    case .boolean:
                        if rowNumber == 0 {
                            let newColumn = Column(alias, .boolean)
                            columns.append(newColumn)
                        }
                        resultRow.append(makeMemoryCell(expressionToken)!)
                    case .numeric:
                        if rowNumber == 0 {
                            let newColumn = Column(alias, .int)
                            columns.append(newColumn)
                        }
                        resultRow.append(makeMemoryCell(expressionToken)!)
                    case .string:
                        if rowNumber == 0 {
                            let newColumn = Column(alias, .text)
                            columns.append(newColumn)
                        }
                        resultRow.append(makeMemoryCell(expressionToken)!)
                    case .identifier(let requestedColumnName):
                        for (i, columnName) in table.columnNames.enumerated() {
                            if requestedColumnName == columnName {
                                if rowNumber == 0 {
                                    let newColumn = Column(alias, table.columnTypes[i])
                                    columns.append(newColumn)
                                }
                                resultRow.append(tableRow[i])
                                break
                            }
                        }
                    default:
                        throw StatementError.misc("Unable to handle this kind of token")
                    }
                case .star:
                    for (i, columnName) in table.columnNames.enumerated() {
                        if rowNumber == 0 {
                            let newColumn = Column(columnName, table.columnTypes[i])
                            columns.append(newColumn)
                        }
                        resultRow.append(tableRow[i])
                    }
                }
            }

            resultRows.append(resultRow)
        }
        return ResultSet(columns, resultRows)
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
