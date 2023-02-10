//
//  Memory.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/7/23.
//

enum MemoryCell {
    case stringValue(String)
    case intValue(Int)
    case booleanValue(Bool)
}

enum ColumnType {
    case int
    case text
    case boolean
}

struct Table {
    var columnNames: [String]
    var columnTypes: [ColumnType]
    var data: [[MemoryCell]]
}

struct MemoryBackend {
    var tables: [String: Table] = [:]

    mutating func createTable(_ cs: CreateStatement) {
        var columnNames: [String] = []
        var columnTypes: [ColumnType] = []
        for case .column(let nameToken, let typeToken) in cs.columns {
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

        switch cs.table.kind {
        case .identifier(let tableName):
            let newTable = Table(columnNames: columnNames, columnTypes: columnTypes, data: [])
            self.tables[tableName] = newTable
        default:
            fatalError("Invalid token for table name")
        }
    }
}
