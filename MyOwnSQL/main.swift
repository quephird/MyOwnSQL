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

        var columnHeader = ""
        for column in results.columns {
            columnHeader.append("| \(column.name) ")
        }
        columnHeader.append("|")
        print(columnHeader)
        let separator = String(repeating: "=", count: columnHeader.count)
        print(separator)

        for row in results.rows {
            var rowLine = ""
            for (i, columnValue) in row.enumerated() {
                let columnWidth = results.columns[i].name.count
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
                rowLine.append(printedValue.padding(toLength: columnWidth, withPad: " ", startingAt: 0))
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
