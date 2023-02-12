//
//  MemoryTests.swift
//  MyOwnSQLTests
//
//  Created by Danielle Kefford on 2/9/23.
//

import XCTest

class MemoryTests: XCTestCase {
    func testSuccessfulExecutionOfCreateStatement() throws {
        let source = "CREATE TABLE dresses (id int, description text, is_in_season boolean)"
        let (tokens, _) = lex(source)
        let (statement, _, _) = parseCreateStatement(tokens!, 0)
        let database = MemoryBackend()

        database.createTable(statement!)
        XCTAssertEqual(database.tables.count, 1)

        let newTable = database.tables["dresses"]
        let expectedColumnNames = ["id", "description", "is_in_season"]
        let actualColumnNames = newTable!.columnNames
        XCTAssertEqual(actualColumnNames, expectedColumnNames)

        let expectedColumnTypes: [ColumnType] = [.int, .text, .boolean]
        let actualColumnTypes = newTable!.columnTypes
        XCTAssertEqual(actualColumnTypes, expectedColumnTypes)
    }

    func testSuccessfulExecutionOfInsertStatement() throws {
        // Create table first...
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean)"
        let (tokens, _) = lex(create)
        let (statement, _, _) = parseCreateStatement(tokens!, 0)
        let database = MemoryBackend()
        database.createTable(statement!)

        // ... and _now_ insert the row...
        let insert = "INSERT INTO dresses VALUES (1, 'Long black velvet gown from Lauren', true)"
        let (tokens2, _) = lex(insert)
        let (statement2, _, _) = parseInsertStatement(tokens2!, 0)
        database.insertTable(statement2!)

        let dressesTable = database.tables["dresses"]!
        let dresses = dressesTable.data
        XCTAssertEqual(dresses.count, 1)

        let actualDress = dresses[0]
        let expectedDress: [MemoryCell] = [
            .intValue(1),
            .stringValue("Long black velvet gown from Lauren"),
            .booleanValue(true)
        ]
        XCTAssertEqual(actualDress, expectedDress)
    }
}
