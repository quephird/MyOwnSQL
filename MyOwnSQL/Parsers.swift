//
//  Parsers.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/3/23.
//

// TODO: Need to think about how to create helper function
//       to check if we have run out of tokens _AND_
//       if the next token matches the expected one

enum ParseHelperResult<T> {
    case failure
    case success(Int, T)
}

// We expect each item in the list of expressions to be in the form:
//
//     <column name> or <numeric value> or <string value>
//
// ... and to be delimited by a comma
func parseExpressions(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<[Expression]> {
    var tokenCursorCopy = tokenCursor
    var expressions: [Expression] = []

    while tokenCursorCopy < tokens.count {
        let maybeLiteralToken = tokens[tokenCursorCopy]

        switch maybeLiteralToken.kind {
        case .identifier, .string, .numeric, .boolean:
            let expression = Expression.literal(maybeLiteralToken)
            expressions.append(expression)
        default:
            return .failure
        }
        // TODO: Need to check if we're out of tokens
        tokenCursorCopy += 1

        guard case .symbol(.comma) = tokens[tokenCursorCopy].kind else {
            break
        }
        tokenCursorCopy += 1
    }

    return .success(tokenCursorCopy, expressions)
}

// For now, the structure of a supported SELECT statement is the following:
//
//     SELECT <one or more expressions> FROM <table name>
func parseSelectStatement(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Statement> {
    var tokenCursorCopy = tokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.select) {
        return .failure
    }
    tokenCursorCopy += 1

    guard case .success(let newTokenCursor, let expressions) = parseExpressions(tokens, tokenCursorCopy) else {
        return .failure
    }
    tokenCursorCopy = newTokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.from) {
        return .failure
    }
    tokenCursorCopy += 1

    guard case .identifier = tokens[tokenCursorCopy].kind else {
        return .failure
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    let statement = SelectStatement(table, expressions)
    return .success(tokenCursorCopy, .select(statement))
}

// We expect each item in the list of column definitions to be in the form:
//
//     <column name> <column type>
//
// ... and to be delimited by a comma
func parseColumns(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<[Definition]> {
    var tokenCursorCopy = tokenCursor
    var columns: [Definition] = []

    while tokenCursorCopy < tokens.count {
        guard case .identifier = tokens[tokenCursorCopy].kind else {
            return .failure
        }
        let name = tokens[tokenCursorCopy]
        tokenCursorCopy += 1

        let maybeDatatype = tokens[tokenCursorCopy]
        guard case .keyword(let keyword) = maybeDatatype.kind,
              [Keyword.int, Keyword.text, Keyword.boolean].contains(keyword) else {
            return .failure
        }
        let column = Definition.column(name, maybeDatatype)
        columns.append(column)
        tokenCursorCopy += 1

        guard case .symbol(.comma) = tokens[tokenCursorCopy].kind else {
            break
        }
        tokenCursorCopy += 1
    }

    // TODO: Need to check count of column definitions
    return .success(tokenCursorCopy, columns)
}

// For now, the structure of a supported CREATE TABLE statement is the following:
//
//     CREATE TABLE <table name> (<one or more column definitions>)
func parseCreateStatement(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Statement> {
    var tokenCursorCopy = tokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.create) {
        return .failure
    }
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.table) {
        return .failure
    }
    tokenCursorCopy += 1

    guard case .identifier = tokens[tokenCursorCopy].kind else {
        return .failure
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.symbol(.leftParenthesis) {
        return .failure
    }
    tokenCursorCopy += 1

    guard case .success(let newTokenCursor, let columns) = parseColumns(tokens, tokenCursorCopy) else {
        return .failure
    }
    tokenCursorCopy = newTokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.symbol(.rightParenthesis) {
        return .failure
    }
    tokenCursorCopy += 1

    let statement = CreateStatement(table, columns)
    return .success(tokenCursorCopy, .create(statement))
}

// For now, the structure of a supported INSERT statement is the following:
//
//     INSERT INTO <table name> VALUES (<one or more expressions>)
func parseInsertStatement(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Statement> {
    var tokenCursorCopy = tokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.insert) {
        return .failure
    }
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.into) {
        return .failure
    }
    tokenCursorCopy += 1

    guard case .identifier = tokens[tokenCursorCopy].kind else {
        return .failure
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.values) {
        return .failure
    }
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.symbol(.leftParenthesis) {
        return .failure
    }
    tokenCursorCopy += 1

    guard case .success(let newTokenCursor, let expressions) = parseExpressions(tokens, tokenCursorCopy) else {
        return .failure
    }
    tokenCursorCopy = newTokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.symbol(.rightParenthesis) {
        return .failure
    }
    tokenCursorCopy += 1

    let statement = InsertStatement(table, expressions)
    return .success(tokenCursorCopy, .insert(statement))
}

func parseStatement(_ tokens: [Token], _ cursor: Int) -> ParseHelperResult<Statement> {
    let parseHelpers = [
        parseCreateStatement,
        parseInsertStatement,
        parseSelectStatement,
    ]
    for helper in parseHelpers {
        switch helper(tokens, cursor) {
        case .success(let cursor, let statement):
            return .success(cursor, statement)
        default:
            continue
        }
    }

    return .failure
}

enum ParseResult {
    case failure
    case success([Statement])
}

// TODO: Need to think about how to improve error messaging
func parse(_ source: String) -> ParseResult {
    guard case .success(let tokens) = lex(source) else {
        return .failure
    }

    var tokenCursor: Int = 0
    var statements: [Statement] = []
    while tokenCursor < tokens.count {
        guard case .success(let newTokenCursor, let statement) = parseStatement(tokens, tokenCursor) else {
            return .failure
        }
        tokenCursor = newTokenCursor
        statements.append(statement)

        if tokenCursor >= tokens.count || tokens[tokenCursor].kind != TokenKind.symbol(.semicolon) {
            return .failure
        }
        tokenCursor += 1
    }

    return .success(statements)
}
