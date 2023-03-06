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
    let input = readLine()

    if input!.isEmpty {
        print("Please enter a statement")
        continue
    }

    switch parse(input!) {
    case .failure(let errorMessage):
        print(errorMessage)
    case .success(let statements):
        for statement in statements {
            switch statement {
            case .create(let createStatement):
                handleCreateTable(createStatement)
            case .insert(let insertStatement):
                handleInsertTable(insertStatement)
            case .select(let selectStatement):
                handleSelectTable(selectStatement)
            }
        }
    }
}

func handleCreateTable(_ statement: CreateStatement) {
    do {
        try database.createTable(statement)
        print("Table created!")
    } catch StatementError.misc(let errorMessage) {
        print(errorMessage)
    } catch {
        print(error.localizedDescription)
    }
}

func handleInsertTable(_ statement: InsertStatement) {
    do {
        try database.insertTable(statement)
        print("One row inserted!")
    } catch StatementError.tableDoesNotExist {
        print("Table does not exist")
    } catch StatementError.misc(let errorMessage) {
        print(errorMessage)
    } catch {
        print(error.localizedDescription)
    }
}

func handleSelectTable(_ statement: SelectStatement) {
    do {
        let results = try database.selectTable(statement)
        if results.rows.isEmpty {
            print("No rows selected")
            return
        }

        // First we need to compute the column widths, starting with the
        // lengths of the column names themselves...
        var columnWidths: [Int] = []
        for column in results.columns {
            columnWidths.append(column.name.count)
        }
        // Next we need to see if any of the column values themselves
        // are wider than their respective column names...
        for row in results.rows {
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
        for (i, column) in results.columns.enumerated() {
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
        for row in results.rows {
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
    } catch StatementError.tableDoesNotExist {
        print("Table does not exist")
    } catch StatementError.columnDoesNotExist {
        print("Column does not exist")
    } catch StatementError.misc(let errorMessage) {
        print(errorMessage)
    } catch {
        print(error.localizedDescription)
    }
}
