//
//  Memory.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/7/23.
//

import Foundation

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

enum StatementError: Error, Equatable, LocalizedError {
    case unsupportedColumnType
    case tableAlreadyExists
    case tableDoesNotExist
    case columnDoesNotExist
    case misc(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedColumnType:
            return "Unsupported column type"
        case .tableAlreadyExists:
            return "Table already exists"
        case .tableDoesNotExist:
            return "Table does not exist"
        case .columnDoesNotExist:
            return "Column does not exist"
        case .misc(let message):
            return message
        }
    }
}

class MemoryBackend {
    var tables: [String: Table] = [:]

    func createTable(_ create: CreateStatement) throws {
        guard case .identifier(let tableName) = create.table.kind else {
            throw StatementError.misc("Invalid token for table name")
        }
        if self.tables[tableName] != nil {
            throw StatementError.tableAlreadyExists
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
        // TODO: Need to check that the number of values is
        //       the same as the number of columns in the target table.
        switch insert.table.kind {
        case .identifier(let tableName):
            if let table = self.tables[tableName] {
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
                        throw StatementError.misc("Unsupported expression")
                    }
                }

                table.data.append(newRow)
                return
            } else {
                throw StatementError.tableDoesNotExist
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
            throw StatementError.tableDoesNotExist
        }

        for (i, item) in select.items.enumerated() {
            var maybeAlias: String? = nil
            if let aliasToken = item.alias, case .identifier(let alias) = aliasToken.kind {
                maybeAlias = alias
            }

            switch item.expression {
            case .term(let token):
                switch token.kind {
                case .boolean:
                    columns.append(Column(maybeAlias == nil ? "col_\(i)" : maybeAlias!, .boolean))
                case .numeric:
                    columns.append(Column(maybeAlias == nil ? "col_\(i)" : maybeAlias!, .int))
                case .string:
                    columns.append(Column(maybeAlias == nil ? "col_\(i)" : maybeAlias!, .text))
                case .identifier(let requestedColumnName):
                    if !table.columnNames.contains(requestedColumnName) {
                        throw StatementError.columnDoesNotExist
                    } else {
                        for (i, columnName) in table.columnNames.enumerated() {
                            if requestedColumnName == columnName {
                                columns.append(Column(maybeAlias == nil ? requestedColumnName : maybeAlias!, table.columnTypes[i]))
                                break
                            }
                        }
                    }
                default:
                    throw StatementError.misc("Unable to handle this kind of token")
                }
            default:
                throw StatementError.misc("Unsupported expression")
            }

        }

        for tableRow in table.data {
            var resultRow: [MemoryCell] = []

            for item in select.items {
                switch item.expression {
                case .term(let token):
                    switch token.kind {
                    case .boolean, .numeric, .string:
                        resultRow.append(makeMemoryCell(token)!)
                    case .identifier(let requestedColumnName):
                        for (i, columnName) in table.columnNames.enumerated() {
                            if requestedColumnName == columnName {
                                resultRow.append(tableRow[i])
                                break
                            }
                        }
                    default:
                        throw StatementError.misc("Unable to handle this kind of token")
                    }
                default:
                    throw StatementError.misc("Unsupported expression")
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
