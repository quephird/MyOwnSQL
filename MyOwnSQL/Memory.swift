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

class Table {
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

    func createTable(_ create: CreateStatement) {
        var columnNames: [String] = []
        var columnTypes: [ColumnType] = []
        for case .column(let nameToken, let typeToken) in create.columns {
            switch nameToken.kind {
            case .identifier(let name):
                columnNames.append(name)
            default:
                fatalError("Invalid token for column name")
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
                    fatalError("Invalid column type")
                }
            default:
                fatalError("Invalid token for column type")
            }
        }

        switch create.table.kind {
        case .identifier(let tableName):
            let newTable = Table(columnNames, columnTypes)
            self.tables[tableName] = newTable
        default:
            fatalError("Invalid token for table name")
        }
    }

    func insertTable(_ insert: InsertStatement) {
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
                            fatalError("Unable to create cell value from token")
                        }
                    }
                }

                table.data.append(newRow)
            } else {
                fatalError("Table does not exist")
            }
        default:
            fatalError("Invalid token for table name")
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
            // TODO: Use fatalError() here for now
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
