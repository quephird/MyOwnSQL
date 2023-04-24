//
//  MemoryTests.swift
//  MyOwnSQLTests
//
//  Created by Danielle Kefford on 2/9/23.
//

import XCTest

class MemoryTests: XCTestCase {
    func testSuccessfulExecutionOfCreateStatement() throws {
        let database = MemoryBackend()
        let source = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(source)

        XCTAssertEqual(database.tables.count, 1)

        let newTable = database.tables["dresses"]
        let expectedColumnNames = ["id", "description", "is_in_season"]
        let actualColumnNames = newTable!.columnNames
        XCTAssertEqual(actualColumnNames, expectedColumnNames)

        let expectedColumnTypes: [ColumnType] = [.int, .text, .boolean]
        let actualColumnTypes = newTable!.columnTypes
        XCTAssertEqual(actualColumnTypes, expectedColumnTypes)
    }

    func testCreateFailsForExistentTable() throws {
        // Create a table first...
        let database = MemoryBackend()
        let firstInput = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(firstInput)

        // ... and now try to create another table with the same name...
        let secondInput = "CREATE TABLE dresses (id INT);"
        let results = database.executeStatements(secondInput)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .failure(.tableAlreadyExists("dresses")))
    }

    func testSuccessfulExecutionOfInsertStatement() throws {
        // Create the table first...
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        // ... and _now_ insert the row from an actual statement...
        let insert = "INSERT INTO dresses VALUES (1, 'Long black velvet gown from Lauren', true);"
        let results = database.executeStatements(insert)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .successfulInsert(1))

        let dressesTable = database.tables["dresses"]!
        let dresses = Array(dressesTable.data.values)
        XCTAssertEqual(dresses.count, 1)

        let actualDress = dresses[0]
        let expectedDress: [MemoryCell] = [
            .intValue(1),
            .textValue("Long black velvet gown from Lauren"),
            .booleanValue(true)
        ]
        XCTAssertEqual(actualDress, expectedDress)
    }

    func testInsertFailsForNonexistentTable() throws {
        // Create the table first...
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        // ... and _now_ insert the row from an actual statement...
        let badInsert = "INSERT INTO does_not_exist VALUES (42);"
        let results = database.executeStatements(badInsert)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .failure(.tableDoesNotExist("does_not_exist")))
    }

    func testInsertFailsForNotEnoughValues() throws {
        // Create the table first...
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        // ... and _now_ insert the row from an actual statement...
        let badInsert = "INSERT INTO dresses VALUES (42);"
        let results = database.executeStatements(badInsert)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .failure(.notEnoughValues))
    }

    func testInsertFailsForTooManyValues() throws {
        // Create the table first...
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        // ... and _now_ insert the row from an actual statement...
        let badInsert = "INSERT INTO dresses VALUES (1, 'Velvet dress', true, 'Bought at Goodwill');"
        let results = database.executeStatements(badInsert)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .failure(.tooManyValues))
    }

    func testSelectLiteralsStatement() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)
        let insert = "INSERT INTO dresses VALUES (1, 'Velvet dress', true);"
        let _ = database.executeStatements(insert)

        let select = "SELECT 42, 'something', false FROM dresses;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

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
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)
        let insert = "INSERT INTO dresses VALUES (1, 'Velvet dress', true);"
        let _ = database.executeStatements(insert)

        let select = "SELECT id, description, is_in_season FROM dresses;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        let expectedColumnNames = ["id", "description", "is_in_season"]
        let actualColumnNames = resultSet.columns.map { column in
            column.name
        }
        XCTAssertEqual(actualColumnNames, expectedColumnNames)

        XCTAssertEqual(resultSet.rows.count, 1)
        let expectedRow: [MemoryCell] = [
            .intValue(1),
            .textValue("Velvet dress"),
            .booleanValue(true)
        ]
        let actualRow = resultSet.rows[0]
        XCTAssertEqual(actualRow, expectedRow)
    }

    func testSelectWithWhereClause() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes (id int, description text, is_fabulous boolean);"
        let _ = database.executeStatements(create)
        let insert1 = "INSERT INTO clothes VALUES (1, 'Long black velvet gown from Lauren', true);"
        let _ = database.executeStatements(insert1)
        let insert2 = "INSERT INTO clothes VALUES (2, 'Linen shirt', false);"
        let _ = database.executeStatements(insert2)

        let select = "SELECT id, description FROM clothes WHERE is_fabulous = true;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        let expectedColumnNames = ["id", "description"]
        let actualColumnNames = resultSet.columns.map { column in
            column.name
        }
        XCTAssertEqual(actualColumnNames, expectedColumnNames)

        XCTAssertEqual(resultSet.rows.count, 1)
        let expectedRow: [MemoryCell] = [
            .intValue(1),
            .textValue("Long black velvet gown from Lauren"),
        ]
        let actualRow = resultSet.rows[0]
        XCTAssertEqual(actualRow, expectedRow)
    }

    func testSelectFailsForBadExpressionInSelectClause() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        // Cannot add string to int
        let select = "SELECT id + description FROM dresses;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(result, .failure(.invalidExpression))
    }

    func testSelectFailsForNonexistentTable() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        let select = "SELECT 42 FROM does_not_exist;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(result, .failure(.tableDoesNotExist("does_not_exist")))
    }

    func testSelectFailsForNonexistentColumn() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        let select = "SELECT does_not_exist FROM dresses;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(result, .failure(.columnDoesNotExist("does_not_exist")))
    }

    func testSelectFailsForWhereClauseReferencingNonexistentColumn() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        let select = "SELECT * FROM dresses WHERE label = 'Lauren';"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(result, .failure(.columnDoesNotExist("label")))
    }

    func testSelectFailsForWhereClauseThatIsNotBooleanExpression() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        let select = "SELECT * FROM dresses WHERE 42;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(result, .failure(.whereClauseNotBooleanExpression))
    }

    func testSelectFailsForWhereClauseThatIsNotValidExpression() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(create)

        // `id` is an int, and so the WHERE clause should be invalid
        let select = "SELECT * FROM dresses WHERE id = '42';"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(result, .failure(.invalidExpression))
    }

    func testDeleteAllRows() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes (id int, description text, is_fabulous boolean);"
        let _ = database.executeStatements(create)
        let insert1 = "INSERT INTO clothes VALUES (1, 'Long black velvet gown from Lauren', true);"
        let _ = database.executeStatements(insert1)
        let insert2 = "INSERT INTO clothes VALUES (2, 'Linen shirt', false);"
        let _ = database.executeStatements(insert2)

        let delete = "DELETE FROM clothes;"
        let deleteResults = database.executeStatements(delete)
        guard let deleteResult = deleteResults.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulDelete(let rowCount) = deleteResult else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(rowCount, 2)

        // Let's make sure there are indeed no rows left
        let select = "SELECT * FROM clothes;"
        let selectResults = database.executeStatements(select)
        guard let selectResult = selectResults.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = selectResult else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(resultSet.rows.count, 0)
    }

    func testDeleteOnlySpecifiedRows() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes (id int, description text, is_fabulous boolean);"
        let _ = database.executeStatements(create)
        let insert1 = "INSERT INTO clothes VALUES (1, 'Long black velvet gown from Lauren', true);"
        let _ = database.executeStatements(insert1)
        let insert2 = "INSERT INTO clothes VALUES (2, 'Linen shirt', false);"
        let _ = database.executeStatements(insert2)

        let delete = "DELETE FROM clothes WHERE is_fabulous = false;"
        let deleteResults = database.executeStatements(delete)
        guard let deleteResult = deleteResults.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulDelete(let rowCount) = deleteResult else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(rowCount, 1)

        let select = "SELECT * FROM clothes;"
        let selectResults = database.executeStatements(select)
        guard let selectResult = selectResults.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = selectResult else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(resultSet.rows.count, 1)

        guard let onlyRow = resultSet.rows.first else {
            XCTFail("Something unexpected happened")
            return
        }
        let expectedRow: [MemoryCell] = [
            .intValue(1),
            .textValue("Long black velvet gown from Lauren"),
            .booleanValue(true)
        ]
        XCTAssertEqual(expectedRow, onlyRow)
    }
}
