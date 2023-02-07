//
//  Parsers.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/3/23.
//

// We expect each item in the list of expressions to be in the form:
//
//     <column name> or <numeric value> or <string value>
//
// ... and to be delimited by a comma
func parseExpressions(_ tokens: [Token], _ tokenCursor: Int) -> ([Expression]?, Int, Bool) {
    var tokenCursorCopy = tokenCursor
    var expressions: [Expression] = []

    while tokenCursorCopy < tokens.count {
        let maybeLiteralToken = tokens[tokenCursorCopy]

        switch maybeLiteralToken.kind {
        case .identifier, .string, .numeric:
            let expression = Expression.literal(maybeLiteralToken)
            expressions.append(expression)
        default:
            return (nil, tokenCursor, false)
        }

        // TODO: Need to check if we're out of tokens
        tokenCursorCopy += 1

        let maybeCommaToken = tokens[tokenCursorCopy]
        if maybeCommaToken.kind == TokenKind.symbol(.comma) {
            tokenCursorCopy += 1
        } else {
            break
        }
    }

    return (expressions, tokenCursorCopy, true)
}

// For now, the structure of a supported SELECT statement is the following:
//
//     SELECT <one or more expressions> FROM <table name>
func parseSelectStatement(_ tokens: [Token], _ tokenCursor: Int) -> (SelectStatement?, Int, Bool) {
    var tokenCursorCopy = tokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.select) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    let (expressions, newTokenCursor, parsed) = parseExpressions(tokens, tokenCursorCopy)
    if !parsed {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy = newTokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.from) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    guard case .identifier = tokens[tokenCursorCopy].kind else {
        return (nil, tokenCursor, false)
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    let statement = SelectStatement(table, expressions!)
    return (statement, tokenCursorCopy, true)
}

// We expect each item in the list of column definitions to be in the form:
//
//     <column name> <column type>
//
// ... and to be delimited by a comma
func parseColumns(_ tokens: [Token], _ tokenCursor: Int) -> ([Definition]?, Int, Bool) {
    var tokenCursorCopy = tokenCursor
    var columns: [Definition] = []

    while tokenCursorCopy < tokens.count {
        guard case .identifier = tokens[tokenCursorCopy].kind else {
            return (nil, tokenCursor, false)
        }
        let name = tokens[tokenCursorCopy]
        tokenCursorCopy += 1

        let maybeDatatype = tokens[tokenCursorCopy]
        guard case .keyword(let keyword) = maybeDatatype.kind,
              [Keyword.int, Keyword.text, Keyword.boolean].contains(keyword) else {
            return (nil, tokenCursor, false)
        }
        let column = Definition.column(name, maybeDatatype)
        columns.append(column)
        tokenCursorCopy += 1

        let maybeCommaToken = tokens[tokenCursorCopy]
        if maybeCommaToken.kind == TokenKind.symbol(.comma) {
            tokenCursorCopy += 1
        } else {
            break
        }
    }

    // TODO: Need to check count of column definitions
    return (columns, tokenCursorCopy, true)
}

// For now, the structure of a supported CREATE TABLE statement is the following:
//
//     CREATE TABLE <table name> <one or more column definitions>
func parseCreateStatement(_ tokens: [Token], _ tokenCursor: Int) -> (CreateStatement?, Int, Bool) {
    var tokenCursorCopy = tokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.create) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.table) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    guard case .identifier = tokens[tokenCursorCopy].kind else {
        return (nil, tokenCursor, false)
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.symbol(.leftParenthesis) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    let (columns, newTokenCursor, parsed) = parseColumns(tokens, tokenCursorCopy)
    if !parsed {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy = newTokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.symbol(.rightParenthesis) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    let statement = CreateStatement(table, columns!)
    return (statement, tokenCursorCopy, true)
}

// For now, the structure of a supported INSERT statement is the following:
//
//     INSERT INTO <table name> VALUES (<one or more expressions>)
func parseInsertStatement(_ tokens: [Token], _ tokenCursor: Int) -> (InsertStatement?, Int, Bool) {
    var tokenCursorCopy = tokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.insert) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.into) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    guard case .identifier = tokens[tokenCursorCopy].kind else {
        return (nil, tokenCursor, false)
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.values) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    if tokens[tokenCursorCopy].kind != TokenKind.symbol(.leftParenthesis) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    let (expressions, newTokenCursor, parsed) = parseExpressions(tokens, tokenCursorCopy)
    if !parsed {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy = newTokenCursor

    if tokens[tokenCursorCopy].kind != TokenKind.symbol(.rightParenthesis) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    let statement = InsertStatement(table, expressions!)
    return (statement, tokenCursorCopy, true)
}
