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
    case whereClauseNotBooleanExpression
    case columnCannotBeNull(String)
    case duplicateColumn(String)
    case columnAmbiguouslyDefined(String)
    case typeMismatch
    case notEnoughValues
    case tooManyValues
    case invalidExpression
    case misc(String)

    var errorDescription: String {
        switch self {
        case .unsupportedColumnType:
            return "Unsupported column type"
        case .tableAlreadyExists(let tableName):
            return "Table \(tableName) already exists"
        case .tableDoesNotExist(let tableName):
            return "Table \(tableName) does not exist"
        case .columnDoesNotExist(let columnName):
            return "Column \(columnName) does not exist"
        case .whereClauseNotBooleanExpression:
            return "WHERE clause must be boolean expression"
        case .columnCannotBeNull(let columnName):
            return "Column \(columnName) cannot be NULL"
        case .duplicateColumn(let columnName):
            return "Column \(columnName) specified more than once"
        case .columnAmbiguouslyDefined(let columnName):
            return "Column \(columnName) ambiguously defined"
        case .typeMismatch:
            return "Type mismatch in SET clause"
        case .notEnoughValues:
            return "Not enough values"
        case .tooManyValues:
            return "Too many values"
        case .invalidExpression:
            return "Invalid expression"
        case .misc(let message):
            return message
        }
    }
}
