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

enum StatementError: Error {
    case misc(String)
}

class MemoryBackend {
    var tables: [String: Table] = [:]

    // TODO: Need to think about the return type of these functions;
    //       they should probably return an enum indicating success
    //       or failure
    func createTable(_ create: CreateStatement) throws {
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

        switch create.table.kind {
        case .identifier(let tableName):
            let newTable = Table(columnNames, columnTypes)
            self.tables[tableName] = newTable
            return
        default:
            throw StatementError.misc("Invalid token for table name")
        }
    }

    func insertTable(_ insert: InsertStatement) throws {
        switch insert.table.kind {
        case .identifier(let tableName):
            if let table = self.tables[tableName] {
                var newRow: [MemoryCell] = []
                for item in insert.items {
                    switch item {
                    case .literal(let token):
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
                throw StatementError.misc("Table does not exist")
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
            throw StatementError.misc("Table does not exist")
        }

        for tableRow in table.data {
            var resultRow: [MemoryCell] = []

            for (i, item) in select.items.enumerated() {
                switch item {
                case .literal(let token):
                    var newColumn: Column
                    switch token.kind {
                    case .boolean:
                        newColumn = Column("col_\(i)", .boolean)
                        columns.append(newColumn)
                        resultRow.append(makeMemoryCell(token)!)
                    case .numeric:
                        newColumn = Column("col_\(i)", .int)
                        columns.append(newColumn)
                        resultRow.append(makeMemoryCell(token)!)
                    case .string:
                        newColumn = Column("col_\(i)", .text)
                        columns.append(newColumn)
                        resultRow.append(makeMemoryCell(token)!)
                    case .identifier(let requestedColumnName):
                        var columnFound = false

                        for (i, columnName) in table.columnNames.enumerated() {
                            if requestedColumnName == columnName {
                                newColumn = Column(requestedColumnName, table.columnTypes[i])
                                columns.append(newColumn)
                                resultRow.append(tableRow[i])
                                columnFound = true
                                break
                            }
                        }

                        if columnFound == false {
                            throw StatementError.misc("Column not found")
                        }
                    default:
                        throw StatementError.misc("Unable to handle this kind of token")
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
