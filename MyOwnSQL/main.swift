//
//  main.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 1/5/23.
//

import LineNoise

let ln = LineNoise()
let database = MemoryBackend()

do {
    try ln.clearScreen()
} catch {
    print(error)
}
print("Welcome to MyOwnSQL!\n")

var done = false
while !done {
    do {
        let input = try ln.getLine(prompt: "SQL> ")
        ln.addHistory(input)

        let results = database.executeStatements(input)
        for result in results {
            switch result {
            case .failure(let error):
                print("\n\(error.errorDescription)")
            case .successfulCreateTable:
                print("\nTable created")
            case .successfulDropTable:
                print("\nTable dropped")
            case .successfulInsert(let rowCount):
                print("\n\(rowCount) row(s) inserted")
            case .successfulSelect(let resultSet):
                print("\n")
                printResultSet(resultSet)
            case .successfulDelete(let rowCount):
                print("\n\(rowCount) row(s) deleted")
            case .successfulUpdate(let rowCount):
                print("\n\(rowCount) row(s) updated")
            }
        }
    } catch LinenoiseError.EOF {
        print("\nExiting...")
        done = true
    } catch {
        print("\n\(error)")
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
            case .null:
                printedValue = ""
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
            case .null:
                printedValue = ""
            }
            rowLine.append("| ")
            rowLine.append(printedValue.padding(toLength: columnWidths[i], withPad: " ", startingAt: 0))
            rowLine.append(" ")
        }
        rowLine.append("|")
        print(rowLine)
    }
}
