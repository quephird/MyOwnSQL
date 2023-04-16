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
    case noMatch
    case failure(String)
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
        // TODO: Consider instead being able to handle tokens
        //       for true and false keywords, and removing the
        //       boolean token type
        case .identifier, .string, .numeric, .boolean:
            let expression = Expression.term(maybeLiteralToken)
            expressions.append(expression)
        default:
            return .failure("Literal expression not found")
        }
        // TODO: Need to check if we're out of tokens
        tokenCursorCopy += 1

        guard tokenCursorCopy < tokens.count, case .symbol(.comma) = tokens[tokenCursorCopy].kind else {
            break
        }
        tokenCursorCopy += 1
    }

    if expressions.isEmpty {
        return .failure("At least one expression was expected")
    }
    return .success(tokenCursorCopy, expressions)
}

func parseExpression(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Expression> {
    var tokenCursorCopy = tokenCursor

    let maybeTermToken = tokens[tokenCursorCopy]

    switch maybeTermToken.kind {
    // TODO: Consider instead being able to handle tokens
    //       for true and false keywords, and removing the
    //       boolean token type
    case .identifier, .string, .numeric, .boolean:
        tokenCursorCopy += 1
        return .success(tokenCursorCopy, Expression.term(maybeTermToken))
    default:
        return .failure("Unsupported expression found")
    }
}

func parseSelectItems(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<[SelectItem]> {
    var tokenCursorCopy = tokenCursor
    var items: [SelectItem] = []

    while tokenCursorCopy < tokens.count {
        var item: SelectItem
        switch parseExpression(tokens, tokenCursorCopy) {
        case .success(let newTokenCursor, let expression):
            tokenCursorCopy = newTokenCursor
            item = SelectItem(expression)
        case .failure(let errorMessage):
            return .failure(errorMessage)
        default:
            return .failure("Could not parse expression")
        }

        if tokens[tokenCursorCopy].kind == TokenKind.keyword(.as) {
            tokenCursorCopy += 1

            let maybeAliasToken = tokens[tokenCursorCopy]
            if case .identifier = maybeAliasToken.kind {
                item.alias = maybeAliasToken
                tokenCursorCopy += 1
            } else {
                return .failure("Alias expected after AS keyword")
            }
        }

        items.append(item)

        guard tokenCursorCopy < tokens.count, case .symbol(.comma) = tokens[tokenCursorCopy].kind else {
            break
        }
        tokenCursorCopy += 1
    }

    if items.isEmpty {
        return .failure("At least one expression was expected")
    }
    return .success(tokenCursorCopy, items)
}

// For now, the structure of a supported SELECT statement is the following:
//
//     SELECT <one or more expressions> FROM <table name>
func parseSelectStatement(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Statement> {
    var tokenCursorCopy = tokenCursor
    var items: [SelectItem]

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.select) {
        return .noMatch
    }
    tokenCursorCopy += 1

    switch parseSelectItems(tokens, tokenCursorCopy) {
    case .success(let newTokenCursor, let newItems):
        tokenCursorCopy = newTokenCursor
        items = newItems
    case .failure(let errorMessage):
        return .failure(errorMessage)
    default:
        return .failure("Unexpected error occurred")
    }

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.keyword(.from) {
        return .failure("Missing FROM keyword")
    }
    tokenCursorCopy += 1

    guard tokenCursorCopy < tokens.count, case .identifier = tokens[tokenCursorCopy].kind else {
        return .failure("Missing table name")
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    let statement = SelectStatement(table, items)
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
            return .failure("Missing column name")
        }
        let name = tokens[tokenCursorCopy]
        tokenCursorCopy += 1

        let maybeDatatype = tokens[tokenCursorCopy]
        guard case .keyword(let keyword) = maybeDatatype.kind,
              [Keyword.int, Keyword.text, Keyword.boolean].contains(keyword) else {
            return .failure("Missing column datatype")
        }
        let column = Definition.column(name, maybeDatatype)
        columns.append(column)
        tokenCursorCopy += 1

        guard tokenCursorCopy < tokens.count, case .symbol(.comma) = tokens[tokenCursorCopy].kind else {
            break
        }
        tokenCursorCopy += 1
    }

    if columns.isEmpty {
        return .failure("At least one column definition was expected")
    }
    return .success(tokenCursorCopy, columns)
}

// For now, the structure of a supported CREATE TABLE statement is the following:
//
//     CREATE TABLE <table name> (<one or more column definitions>)
func parseCreateStatement(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Statement> {
    var tokenCursorCopy = tokenCursor
    var columns: [Definition]

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.create) {
        return .noMatch
    }
    tokenCursorCopy += 1

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.keyword(.table) {
        return .failure("Missing TABLE keyword")
    }
    tokenCursorCopy += 1

    guard tokenCursorCopy < tokens.count, case .identifier = tokens[tokenCursorCopy].kind else {
        return .failure("Missing table name")
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.symbol(.leftParenthesis) {
        return .failure("Missing left parenthesis")
    }
    tokenCursorCopy += 1

    switch parseColumns(tokens, tokenCursorCopy) {
    case .failure(let errorMessage):
        return .failure(errorMessage)
    case .success(let newTokenCursor, let newColumns):
        tokenCursorCopy = newTokenCursor
        columns = newColumns
    default:
        return .failure("Unexpected error occurred")
    }

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.symbol(.rightParenthesis) {
        return .failure("Missing right parenthesis")
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
    var expressions: [Expression]

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.insert) {
        return .noMatch
    }
    tokenCursorCopy += 1

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.keyword(.into) {
        return .failure("Missing INTO keyword")
    }
    tokenCursorCopy += 1

    guard tokenCursorCopy < tokens.count, case .identifier = tokens[tokenCursorCopy].kind else {
        return .failure("Missing table name")
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.keyword(.values) {
        return .failure("Missing VALUES keyword")
    }
    tokenCursorCopy += 1

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.symbol(.leftParenthesis) {
        return .failure("Missing left parenthesis")
    }
    tokenCursorCopy += 1

    switch parseExpressions(tokens, tokenCursorCopy) {
    case .failure(let errorMessage):
        return .failure(errorMessage)
    case .success(let newTokenCursor, let newExpressions):
        tokenCursorCopy = newTokenCursor
        expressions = newExpressions
    default:
        return .failure("Unexpected error occurred")
    }

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.symbol(.rightParenthesis) {
        return .failure("Missing right parenthesis")
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
        case .failure(let errorMessage):
            return .failure(errorMessage)
        default:
            continue
        }
    }

    return .noMatch
}

enum ParseResult {
    case failure(String)
    case success([Statement])
}

func parse(_ source: String) -> ParseResult {
    var tokens: [Token]
    switch lex(source) {
    case .failure(let errorMessage):
        return .failure(errorMessage)
    case .success(let newTokens):
        tokens = newTokens
    }

    var tokenCursor: Int = 0
    var statements: [Statement] = []
    while tokenCursor < tokens.count {
        switch parseStatement(tokens, tokenCursor) {
        case .failure(let errorMessage):
            return .failure(errorMessage)
        case .success(let newTokenCursor, let newStatement):
            tokenCursor = newTokenCursor
            statements.append(newStatement)
        default:
            return .failure("Unsupported statement")
        }

        if tokenCursor >= tokens.count || tokens[tokenCursor].kind != TokenKind.symbol(.semicolon) {
            return .failure("Missing semicolon at end of statement")
        }
        tokenCursor += 1
    }

    return .success(statements)
}
