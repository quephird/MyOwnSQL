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

    func testSuccessfulDropTableStatement() throws {
        let database = MemoryBackend()
        let setup = "CREATE TABLE dresses (id int, description text, is_in_season boolean);"
        let _ = database.executeStatements(setup)

        let dropTable = "DROP TABLE dresses;"
        let results = database.executeStatements(dropTable)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .successfulDropTable)
        XCTAssertNil(database.tables["dresses"])
    }

    func testDropTableFailsForNonExistentTable() throws {
        let database = MemoryBackend()
        let dropTable = "DROP TABLE dresses;"
        let results = database.executeStatements(dropTable)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .failure(.tableDoesNotExist("dresses")))
    }

    func testCreateStatementWithNullalityQualifiers() throws {
        let database = MemoryBackend()
        let firstInput = "CREATE TABLE foo(bar int not null, baz text null, quux boolean);"
        let _ = database.executeStatements(firstInput)

        guard let newTable = database.tables["foo"] else {
            XCTFail("Something unexpected happened")
            return
        }
        let expectedNullalities = [false, true, true]
        let actualNullalities = newTable.columnNullalities
        XCTAssertEqual(actualNullalities, expectedNullalities)
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

    func testSuccessfulExecutionOfInsertStatementWithMultipleTuples() throws {
        // Create the table first...
        let database = MemoryBackend()
        let create = "CREATE TABLE exclamations(id INT NOT NULL, remark TEXT NOT NULL);"
        let _ = database.executeStatements(create)

        // ... and _now_ insert the row from an actual statement...
        let insert = "INSERT INTO exclamations VALUES(1, 'WHEEEEE!!!'), (2, 'ZOMGGGG'), (3, 'Holy crap, I am doing this!');"
        let results = database.executeStatements(insert)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .successfulInsert(3))

        guard let table = database.tables["exclamations"] else {
            XCTFail("Something unexpected happened")
            return
        }
        let rows = Array(table.data.values)
        XCTAssertEqual(rows.count, 3)

        let expectedRows: [[MemoryCell]] = [
            [
                .intValue(1),
                .textValue("WHEEEEE!!!"),
            ],
            [
                .intValue(2),
                .textValue("ZOMGGGG"),
            ],
            [
                .intValue(3),
                .textValue("Holy crap, I am doing this!"),
            ],
        ]
        let actualRowsSorted = rows.sorted(by: { (row1, row2) -> Bool in
            switch (row1[0], row2[0]) {
            case (.intValue(let id1), .intValue(let id2)):
                return id1 < id2
            default:
                return false
            }
        })
        XCTAssertEqual(actualRowsSorted, expectedRows)
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

    func testInsertFailsWhenInsertingNullValueIntoNotNullColumn() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses(id int NOT NULL, description TEXT);"
        let _ = database.executeStatements(create)

        let badInsert = "INSERT INTO dresses VALUES (null, 'Velvet dress');"
        let results = database.executeStatements(badInsert)

        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        XCTAssertEqual(result, .failure(.columnCannotBeNull("id")))
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

    func testSelectFromTableWithNullValues() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes (id INT NOT NULL, description TEXT NOT NULL, comment TEXT NULL);"
        let _ = database.executeStatements(create)
        let insert = "INSERT INTO clothes VALUES (1, 'Long black velvet gown from Lauren', NULL);"
        let _ = database.executeStatements(insert)

        let select = "SELECT id, description, comment FROM clothes;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(resultSet.rows.count, 1)
        let expectedRow: [MemoryCell] = [
            .intValue(1),
            .textValue("Long black velvet gown from Lauren"),
            .null
        ]
        let actualRow = resultSet.rows[0]
        XCTAssertEqual(actualRow, expectedRow)
    }

    func testSelectingExpressionsInvolvingNullsInVariousWays() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE foo(id INT);"
        let _ = database.executeStatements(create)
        let insert = "INSERT INTO foo VALUES (1);"
        let _ = database.executeStatements(insert)

        for (select, expectedValue): (String, MemoryCell) in [
            ("SELECT 1 + NULL FROM foo;", .null),
            ("SELECT 1 * NULL FROM foo;", .null),
            ("SELECT 'null' || NULL FROM foo;", .null),
            ("SELECT 1 = NULL FROM foo;", .booleanValue(false)),
            ("SELECT 1 != NULL FROM foo;", .booleanValue(false)),
            ("SELECT TRUE AND NULL FROM foo;", .booleanValue(false)),
            ("SELECT TRUE OR NULL FROM foo;", .booleanValue(true)),
            ("SELECT 1 IS NULL FROM foo;", .booleanValue(false)),
            ("SELECT 'one' IS NULL FROM foo;", .booleanValue(false)),
            ("SELECT TRUE IS NULL FROM foo;", .booleanValue(false)),
            ("SELECT 1 IS NOT NULL FROM foo;", .booleanValue(true)),
            ("SELECT 'one' IS NOT NULL FROM foo;", .booleanValue(true)),
            ("SELECT TRUE IS NOT NULL FROM foo;", .booleanValue(true)),
        ] {
            let results = database.executeStatements(select)
            guard let result = results.first else {
                XCTFail("Something unexpected happened")
                return
            }

            guard case .successfulSelect(let resultSet) = result else {
                XCTFail("Something unexpected happened")
                return
            }

            XCTAssertEqual(resultSet.rows.count, 1)
            let expectedRow: [MemoryCell] = [
                expectedValue
            ]
            let actualRow = resultSet.rows[0]
            XCTAssertEqual(actualRow, expectedRow)
        }
    }

    func testSelectWithWhereClauseWithIsNullExpression() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes(id INT NOT NULL, description TEXT NOT NULL, comment TEXT NULL);"
        let _ = database.executeStatements(create)
        for insert in [
            "INSERT INTO clothes VALUES(1, 'Velvet dress', 'This one is purple');",
            "INSERT INTO clothes VALUES(2, 'Linen shirt', NULL);",
            "INSERT INTO clothes VALUES(3, 'Catsuit from Black Milk', 'This one is HAWT');",
        ] {
            let _ = database.executeStatements(insert)
        }

        let select = "SELECT * FROM clothes WHERE comment IS NULL;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(resultSet.rows.count, 1)
        let expectedRow: [MemoryCell] = [
            .intValue(2),
            .textValue("Linen shirt"),
            .null,
        ]
        let actualRow = resultSet.rows[0]
        XCTAssertEqual(actualRow, expectedRow)
    }

    func testSelectWithWhereClauseWithNestedIsNullExpression() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes(id INT NOT NULL, description TEXT NOT NULL, comment TEXT NULL);"
        let _ = database.executeStatements(create)
        for insert in [
            "INSERT INTO clothes VALUES(1, 'Velvet dress', 'This one is purple');",
            "INSERT INTO clothes VALUES(2, 'Linen shirt', NULL);",
            "INSERT INTO clothes VALUES(3, 'Catsuit from Black Milk', 'This one is HAWT');",
        ] {
            let _ = database.executeStatements(insert)
        }

        let select = "SELECT * FROM clothes WHERE comment IS NULL OR id = 1;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(resultSet.rows.count, 2)
        let expectedIds = [1, 2]
        let actualIds: [Int] = resultSet.rows.map { row in
            if case .intValue(let id) = row[0] {
                return id
            } else {
                return -1
            }
        }.sorted()
        XCTAssertEqual(actualIds, expectedIds)
    }

    func testSelectWithOneOrderByClauseExpression() throws {
        let database = MemoryBackend()
        let setup = """
CREATE TABLE parts(id INT NOT NULL, name TEXT NOT NULL, color TEXT NOT NULL, weight INT NOT NULL, city TEXT NOT NULL);
INSERT INTO parts VALUES(1, 'Nut', 'Red', 12, 'London');
INSERT INTO parts VALUES(2, 'Bolt', 'Green', 17, 'Paris');
INSERT INTO parts VALUES(3, 'Screw', 'Blue', 17, 'Oslo');
INSERT INTO parts VALUES(4, 'Screw', 'Red', 14, 'London');
INSERT INTO parts VALUES(5, 'Cam', 'Blue', 12, 'Paris');
INSERT INTO parts VALUES(6, 'Cog', 'Red', 19, 'London');
"""
        let _ = database.executeStatements(setup)

        let select = "SELECT * FROM parts ORDER BY id;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        let expectedIds: [MemoryCell] = [
            .intValue(1),
            .intValue(2),
            .intValue(3),
            .intValue(4),
            .intValue(5),
            .intValue(6),
        ]
        let actualIds = resultSet.rows.map { row in
            return row[0]
        }
        XCTAssertEqual(actualIds, expectedIds)
    }

    func testSelectWithMultipleOrderByClauseExpressions() throws {
        let database = MemoryBackend()
        let setup = """
CREATE TABLE parts(id INT NOT NULL, name TEXT NOT NULL, color TEXT NOT NULL, weight INT NOT NULL, city TEXT NOT NULL);
INSERT INTO parts VALUES(1, 'Nut', 'Red', 12, 'London');
INSERT INTO parts VALUES(2, 'Bolt', 'Green', 17, 'Paris');
INSERT INTO parts VALUES(3, 'Screw', 'Blue', 17, 'Oslo');
INSERT INTO parts VALUES(4, 'Screw', 'Red', 14, 'London');
INSERT INTO parts VALUES(5, 'Cam', 'Blue', 12, 'Paris');
INSERT INTO parts VALUES(6, 'Cog', 'Red', 19, 'London');
"""
        let _ = database.executeStatements(setup)

        let select = "SELECT * FROM parts ORDER BY city, name;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        let expectedIds: [MemoryCell] = [
            .intValue(6),
            .intValue(1),
            .intValue(4),
            .intValue(3),
            .intValue(2),
            .intValue(5),
        ]
        let actualIds = resultSet.rows.map { row in
            return row[0]
        }
        XCTAssertEqual(actualIds, expectedIds)
    }

    func testSelectWithWhereClauseAndOrderByClause() throws {
        let database = MemoryBackend()
        let setup = """
CREATE TABLE parts(id INT NOT NULL, name TEXT NOT NULL, color TEXT NOT NULL, weight INT NOT NULL, city TEXT NOT NULL);
INSERT INTO parts VALUES(1, 'Nut', 'Red', 12, 'London');
INSERT INTO parts VALUES(2, 'Bolt', 'Green', 17, 'Paris');
INSERT INTO parts VALUES(3, 'Screw', 'Blue', 17, 'Oslo');
INSERT INTO parts VALUES(4, 'Screw', 'Red', 14, 'London');
INSERT INTO parts VALUES(5, 'Cam', 'Blue', 12, 'Paris');
INSERT INTO parts VALUES(6, 'Cog', 'Red', 19, 'London');
"""
        let _ = database.executeStatements(setup)

        let select = "SELECT * FROM parts WHERE city = 'London' ORDER BY weight;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        let expectedIds: [MemoryCell] = [
            .intValue(1),
            .intValue(4),
            .intValue(6),
        ]
        let actualIds = resultSet.rows.map { row in
            return row[0]
        }
        XCTAssertEqual(actualIds, expectedIds)
    }

    func testSelectWithOrderByClauseSortsNullsToBottom() throws {
        let database = MemoryBackend()
        let setup = """
CREATE TABLE customers(id INT NOT NULL, name TEXT NOT NULL, email_address TEXT NULL);
INSERT INTO customers VALUES(1, 'Danielle', 'danielle@danielle.com');
INSERT INTO customers VALUES(2, 'Becca', NULL);
INSERT INTO customers VALUES(3, 'Joshu', 'joshu@joshu.com');
INSERT INTO customers VALUES(4, 'Nic', NULL);
INSERT INTO customers VALUES(5, 'David', 'david@david.com');
"""
        let _ = database.executeStatements(setup)

        let select = "SELECT * FROM customers ORDER BY email_address;"
        let results = database.executeStatements(select)
        guard let result = results.first, case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        let expectedIds: [MemoryCell] = [
            .textValue("danielle@danielle.com"),
            .textValue("david@david.com"),
            .textValue("joshu@joshu.com"),
            .null,
            .null,
        ]
        let actualIds = resultSet.rows.map { row in
            return row[2]
        }
        XCTAssertEqual(actualIds, expectedIds)
    }

    func testSelectWithOrderByClauseWithExplicitDescSort() throws {
        let database = MemoryBackend()
        let setup = """
CREATE TABLE parts(id INT NOT NULL, name TEXT NOT NULL, color TEXT NOT NULL, weight INT NOT NULL, city TEXT NOT NULL);
INSERT INTO parts VALUES(1, 'Nut', 'Red', 12, 'London');
INSERT INTO parts VALUES(2, 'Bolt', 'Green', 17, 'Paris');
INSERT INTO parts VALUES(3, 'Screw', 'Blue', 17, 'Oslo');
INSERT INTO parts VALUES(4, 'Screw', 'Red', 14, 'London');
INSERT INTO parts VALUES(5, 'Cam', 'Blue', 12, 'Paris');
INSERT INTO parts VALUES(6, 'Cog', 'Red', 19, 'London');
"""
        let _ = database.executeStatements(setup)

        let select = "SELECT * FROM parts ORDER BY id DESC;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        let expectedIds: [MemoryCell] = [
            .intValue(6),
            .intValue(5),
            .intValue(4),
            .intValue(3),
            .intValue(2),
            .intValue(1),
        ]
        let actualIds = resultSet.rows.map { row in
            return row[0]
        }
        XCTAssertEqual(actualIds, expectedIds)
    }

    func testSelectWithOrderByClauseDescAndAsc() throws {
        let database = MemoryBackend()
        let setup = """
CREATE TABLE parts(id INT NOT NULL, name TEXT NOT NULL, color TEXT NOT NULL, weight INT NOT NULL, city TEXT NOT NULL);
INSERT INTO parts VALUES(1, 'Nut', 'Red', 12, 'London');
INSERT INTO parts VALUES(2, 'Bolt', 'Green', 17, 'Paris');
INSERT INTO parts VALUES(3, 'Screw', 'Blue', 17, 'Oslo');
INSERT INTO parts VALUES(4, 'Screw', 'Red', 14, 'London');
INSERT INTO parts VALUES(5, 'Cam', 'Blue', 12, 'Paris');
INSERT INTO parts VALUES(6, 'Cog', 'Red', 19, 'London');
"""
        let _ = database.executeStatements(setup)

        let select = "SELECT * FROM parts ORDER BY city ASC, name DESC;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        let expectedIds: [MemoryCell] = [
            .intValue(4),
            .intValue(1),
            .intValue(6),
            .intValue(3),
            .intValue(5),
            .intValue(2),
        ]
        let actualIds = resultSet.rows.map { row in
            return row[0]
        }
        XCTAssertEqual(actualIds, expectedIds)
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

    func testSelectFailsForOrderByClauseReferencingNonexistentColumn() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE dresses (id int, description text, is_fabulous boolean);"
        let _ = database.executeStatements(create)

        let select = "SELECT * FROM dresses ORDER BY is_velvet;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(result, .failure(.columnDoesNotExist("is_velvet")))
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

    func testUpdateAllRows() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes (id int, description text, is_fabulous boolean);"
        let _ = database.executeStatements(create)
        let insert1 = "INSERT INTO clothes VALUES (1, 'Long black velvet gown from Lauren', false);"
        let _ = database.executeStatements(insert1)
        let insert2 = "INSERT INTO clothes VALUES (2, 'Catsuit from Black Milk', false);"
        let _ = database.executeStatements(insert2)

        let update = "UPDATE clothes SET is_fabulous = true;"
        let updateResults = database.executeStatements(update)
        guard let updateResult = updateResults.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulUpdate(let rowCount) = updateResult else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(rowCount, 2)

        // Let's make sure we updated both rows
        let select = "SELECT is_fabulous FROM clothes;"
        let selectResults = database.executeStatements(select)
        guard let selectResult = selectResults.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = selectResult else {
            XCTFail("Something unexpected happened")
            return
        }
        for row in resultSet.rows {
            XCTAssertEqual(row[0], .booleanValue(true))
        }
    }

    func testUpdateOnlyCertainRows() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE some_table (id int, was_updated boolean);"
        let _ = database.executeStatements(create)
        let insert1 = "INSERT INTO some_table VALUES (1, false);"
        let _ = database.executeStatements(insert1)
        let insert2 = "INSERT INTO some_table VALUES (2, false);"
        let _ = database.executeStatements(insert2)
        let insert3 = "INSERT INTO some_table VALUES (3, false);"
        let _ = database.executeStatements(insert3)

        let update = "UPDATE some_table SET was_updated = true WHERE id = 2;"
        let updateResults = database.executeStatements(update)
        guard let updateResult = updateResults.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulUpdate(let rowCount) = updateResult else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(rowCount, 1)

        // Let's make sure we updated only one of the rows
        let select = "SELECT id, was_updated FROM some_table;"
        let selectResults = database.executeStatements(select)
        guard let selectResult = selectResults.first else {
            XCTFail("Something unexpected happened")
            return
        }

        guard case .successfulSelect(let resultSet) = selectResult else {
            XCTFail("Something unexpected happened")
            return
        }
        for row in resultSet.rows {
            if row[0] == .intValue(2) {
                XCTAssertEqual(row[1], .booleanValue(true))
            } else {
                XCTAssertEqual(row[1], .booleanValue(false))
            }
        }
    }

    func testUpdateSetsOneColumnToNull() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes(id INT NOT NULL, description TEXT NOT NULL, comment TEXT NULL);"
        let _ = database.executeStatements(create)
        let insert = "INSERT INTO clothes VALUES(2, 'Linen shirt', 'This is my favorite');"
        let _ = database.executeStatements(insert)

        let update = "UPDATE clothes SET comment = NULL;"
        let _ = database.executeStatements(update)

        let select = "SELECT comment FROM clothes;"
        let results = database.executeStatements(select)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        guard case .successfulSelect(let resultSet) = result else {
            XCTFail("Something unexpected happened")
            return
        }

        XCTAssertEqual(resultSet.rows.count, 1)
        let expectedRow: [MemoryCell] = [
            .null,
        ]
        let actualRow = resultSet.rows[0]
        XCTAssertEqual(actualRow, expectedRow)
    }

    func testUpdateFailsDueToColumnNotBeingNullable() throws {
        let database = MemoryBackend()
        let create = "CREATE TABLE clothes(id INT NOT NULL, description TEXT NOT NULL, comment TEXT NULL);"
        let _ = database.executeStatements(create)
        let insert = "INSERT INTO clothes VALUES(1, 'Velvet dress', 'This is my favorite');"
        let _ = database.executeStatements(insert)

        let update = "UPDATE clothes SET description = NULL;"
        let results = database.executeStatements(update)
        guard let result = results.first else {
            XCTFail("Something unexpected happened")
            return
        }
        guard case .failure(.columnCannotBeNull("description")) = result else {
            XCTFail("Something unexpected happened")
            return
        }
    }
}
