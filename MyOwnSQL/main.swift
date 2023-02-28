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
                do {
                    try database.createTable(createStatement)
                    print("Table created!")
                } catch StatementError.misc(let errorMessage) {
                    print(errorMessage)
                }
            case .insert(let insertStatement):
                do {
                    try database.insertTable(insertStatement)
                    print("One row inserted!")
                } catch StatementError.tableDoesNotExist {
                    print("Table does not exist")
                } catch StatementError.misc(let errorMessage) {
                    print(errorMessage)
                }
            case .select(let selectStatement):
                do {
                    let results = try database.selectTable(selectStatement)
                    if results.rows.isEmpty {
                        print("No rows selected")
                    } else {
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
                            for columnValue in row {
                                switch columnValue {
                                case .intValue(let integer):
                                    rowLine.append("| \(integer) ")
                                case .textValue(let string):
                                    rowLine.append("| \(string) ")
                                case .booleanValue(let boolean):
                                    rowLine.append("| \(boolean) ")
                                }
                            }
                            rowLine.append("|")
                            print(rowLine)
                        }
                    }
                } catch StatementError.tableDoesNotExist {
                    print("Table does not exist")
                } catch StatementError.columnDoesNotExist {
                    print("Column does not exist")
                } catch StatementError.misc(let errorMessage) {
                    print(errorMessage)
                }
            }
        }
    }
}
