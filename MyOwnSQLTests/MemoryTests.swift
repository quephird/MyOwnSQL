//
//  MemoryTests.swift
//  MyOwnSQLTests
//
//  Created by Danielle Kefford on 2/9/23.
//

import XCTest

class MemoryTests: XCTestCase {
    func testSuccessfulExecutionOfCreateStatement() throws {
        let source = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        guard case .success(let statements) = parse(source) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        guard case .create(let statement) = statements[0] else {
            XCTFail("Unexpected statement type encountered")
            return
        }

        let database = MemoryBackend()
        guard case .created = database.createTable(statement) else {
            XCTFail("Table not created unexpectedly")
            return
        }

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
        // Create table manually first...
        let columnNames = ["id", "description", "is_in_season"]
        let columnTypes: [ColumnType] = [.int, .text, .boolean]
        let table = Table(columnNames, columnTypes)
        let database = MemoryBackend()
        database.tables = ["dresses": table]

        // ... and _now_ insert the row from an actual statement...
        let source = "INSERT INTO dresses VALUES (1, 'Long black velvet gown from Lauren', true);"
        guard case .success(let statements) = parse(source) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        guard case .insert(let statement) = statements[0] else {
            XCTFail("Unexpected statement type encountered")
            return
        }
        database.insertTable(statement)

        let dressesTable = database.tables["dresses"]!
        let dresses = dressesTable.data
        XCTAssertEqual(dresses.count, 1)

        let actualDress = dresses[0]
        let expectedDress: [MemoryCell] = [
            .intValue(1),
            .textValue("Long black velvet gown from Lauren"),
            .booleanValue(true)
        ]
        XCTAssertEqual(actualDress, expectedDress)
    }

    func testSelectLiteralsStatement() throws {
        // Create table manually first...
        let columnNames = ["id", "description", "is_in_season"]
        let columnTypes: [ColumnType] = [.int, .text, .boolean]
        let table = Table(columnNames, columnTypes)

        // Now create some data manually...
        let row: [MemoryCell] = [
            .intValue(1),
            .textValue("Long black velvet gown from Lauren"),
            .booleanValue(true)
        ]
        table.data.append(row)

        let database = MemoryBackend()
        database.tables = ["dresses": table]

        // ... and _now_ SELECT a set of expressions from the table...
        let source = "SELECT 42, 'something', false FROM dresses;"
        guard case .success(let statements) = parse(source) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        guard case .select(let statement) = statements[0] else {
            XCTFail("Unexpected statement type encountered")
            return
        }
        let resultSet = database.selectTable(statement)
        let expectedColumnNames = ["col_0", "col_1", "col_2"]
        let actualColumnNames = resultSet.columns.map { column in
            column.name
        }
        XCTAssertEqual(actualColumnNames, expectedColumnNames)

        XCTAssertEqual(resultSet.rows.count, 1)
        let expectedRow: [MemoryCell] = [
            .intValue(42),
            .textValue("something"),
            .booleanValue(false)
        ]
        let actualRow = resultSet.rows[0]
        XCTAssertEqual(actualRow, expectedRow)
    }

    func testSelectActualColumnsStatement() throws {
        // Create table manually first...
        let columnNames = ["id", "description", "is_in_season"]
        let columnTypes: [ColumnType] = [.int, .text, .boolean]
        let table = Table(columnNames, columnTypes)

        // Now create some data manually...
        let row: [MemoryCell] = [
            .intValue(1),
            .textValue("Long black velvet gown from Lauren"),
            .booleanValue(true)
        ]
        table.data.append(row)

        let database = MemoryBackend()
        database.tables = ["dresses": table]

        // ... and _now_ SELECT a set of expressions from the table...
        let source = "SELECT id, description, is_in_season FROM dresses;"
        guard case .success(let statements) = parse(source) else {
            XCTFail("Parsing failed unexpectedly")
            return
        }
        guard case .select(let statement) = statements[0] else {
            XCTFail("Unexpected statement type encountered")
            return
        }
        let resultSet = database.selectTable(statement)
        let expectedColumnNames = ["id", "description", "is_in_season"]
        let actualColumnNames = resultSet.columns.map { column in
            column.name
        }
        XCTAssertEqual(actualColumnNames, expectedColumnNames)

        XCTAssertEqual(resultSet.rows.count, 1)
        let expectedRow: [MemoryCell] = [
            .intValue(1),
            .textValue("Long black velvet gown from Lauren"),
            .booleanValue(true)
        ]
        let actualRow = resultSet.rows[0]
        XCTAssertEqual(actualRow, expectedRow)
    }
}
