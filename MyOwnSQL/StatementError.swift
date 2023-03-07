//
//  StatementError.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 3/7/23.
//

import Foundation

enum StatementError: Error, Equatable, LocalizedError {
    case unsupportedColumnType
    case tableAlreadyExists(String)
    case tableDoesNotExist(String)
    case columnDoesNotExist(String)
    case notEnoughValues
    case tooManyValues
    case misc(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedColumnType:
            return "Unsupported column type"
        case .tableAlreadyExists(let tableName):
            return "Table \(tableName) already exists"
        case .tableDoesNotExist(let tableName):
            return "Table \(tableName) does not exist"
        case .columnDoesNotExist(let columnName):
            return "Column \(columnName) does not exist"
        case .notEnoughValues:
            return "Not enough values"
        case .tooManyValues:
            return "Too many values"
        case .misc(let message):
            return message
        }
    }
}
