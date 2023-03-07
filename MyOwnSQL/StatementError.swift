//
//  StatementError.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 3/7/23.
//

import Foundation

enum StatementError: Error, Equatable, LocalizedError {
    case unsupportedColumnType
    case tableAlreadyExists
    case tableDoesNotExist
    case columnDoesNotExist
    case notEnoughValues
    case tooManyValues
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
        case .notEnoughValues:
            return "Not enough values"
        case .tooManyValues:
            return "Too many values"
        case .misc(let message):
            return message
        }
    }
}
