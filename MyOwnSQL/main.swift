//
//  main.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 1/5/23.
//

import Foundation

let database = MemoryBackend()
print("Welcome to MyOwnSQL!\n")

while true {
    print("SQL> ", terminator: "")

    guard let input = readLine() else {
        print("Please enter a statement")
        continue
    }

    let results = database.executeStatements(input)
    for result in results {
        switch result {
        case .failure(let error):
            print(error.errorDescription)
        case .successfulCreateTable:
            print("Table created")
        case .successfulInsert(let rows):
            print("\(rows) row(s) inserted")
        case .successfulSelect(let resultSet):
            printResultSet(resultSet)
        }
    }
}

func printResultSet(_ resultSet: ResultSet) {
    if resultSet.rows.isEmpty {
        print("No rows selected")
        return
    }

    // First we need to compute the column widths, starting with the
    // lengths of the column names themselves...
    var columnWidths: [Int] = []
    for column in resultSet.columns {
        columnWidths.append(column.name.count)
    }
    // Next we need to see if any of the column values themselves
    // are wider than their respective column names...
    for row in resultSet.rows {
        for (i, column) in row.enumerated() {
            var printedValue: String
            switch column {
            case .intValue(let integer):
                printedValue = String(integer)
            case .textValue(let string):
                printedValue = string
            case .booleanValue(let boolean):
                printedValue = String(boolean)
            }
            if printedValue.count > columnWidths[i] {
                columnWidths[i] = printedValue.count
            }
        }
    }

    // Now we can finally print the column header
    var columnHeader = ""
    for (i, column) in resultSet.columns.enumerated() {
        columnHeader.append("| ")
        columnHeader.append(column.name.padding(toLength: columnWidths[i], withPad: " ", startingAt: 0))
        columnHeader.append(" ")
    }
    columnHeader.append("|")
    print(columnHeader)
    let separator = String(repeating: "=", count: columnHeader.count)
    print(separator)

    // ... and then we can print the result set, with padding
    // to insure that all columns are aligned.
    for row in resultSet.rows {
        var rowLine = ""
        for (i, columnValue) in row.enumerated() {
            var printedValue: String
            switch columnValue {
            case .intValue(let integer):
                printedValue = String(integer)
            case .textValue(let string):
                printedValue = string
            case .booleanValue(let boolean):
                printedValue = String(boolean)
            }
            rowLine.append("| ")
            rowLine.append(printedValue.padding(toLength: columnWidths[i], withPad: " ", startingAt: 0))
            rowLine.append(" ")
        }
        rowLine.append("|")
        print(rowLine)
    }
}
