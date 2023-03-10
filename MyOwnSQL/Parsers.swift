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

// NOTA BENE: This function will eventually need to take another parameter
//            denoting which tokens should be considered to delimit the expression,
//            primarily because parseSelectItem and parseInsertValues share this
//            function and those delimiting tokens differ between them, but also
//            because when we tackle parsing of binary expressions, we will not
//            necessarily know how many tokens comprise them. For now, we can get
//            away with just looking at the one current token.
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
        return .failure("Term expression not found")
    }
}

// We expect each item in the list of select items to be in the form:
//
//     <expression>
//
// ... OR
//
//     <expression> AS <identifier>
//
// ... and separated by a comma token
func parseSelectItems(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<[SelectItem]> {
    var tokenCursorCopy = tokenCursor
    var items: [SelectItem] = []

    while tokenCursorCopy < tokens.count {
        if case .symbol(.asterisk) = tokens[tokenCursorCopy].kind {
            items.append(.star)
            tokenCursorCopy += 1
        } else {
            guard case .success(let newTokenCursorCopy, let expression) = parseExpression(tokens, tokenCursorCopy) else {
                return .failure("Expression expected but not found")
            }
            tokenCursorCopy = newTokenCursorCopy

            if case .keyword(.as) = tokens[tokenCursorCopy].kind {
                tokenCursorCopy += 1

                guard case .identifier = tokens[tokenCursorCopy].kind else {
                    return .failure("Identifier expected after AS keyword")
                }
                items.append(.expressionWithAlias(expression, tokens[tokenCursorCopy]))
                tokenCursorCopy += 1
            } else {
                items.append(.expression(expression))
            }
        }

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
// ... and separated by a comma
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

// Ee expect each item in the list of insert values to be in the form:
//
//     <expression>
//
// ... and separated by a comma token. Unlike in parseSelectItems(),
// aliases are not allowed.
func parseInsertValues(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<[Expression]> {
    var tokenCursorCopy = tokenCursor
    var expressions: [Expression] = []

    while tokenCursorCopy < tokens.count {
        guard case .success(let newTokenCursorCopy, let expression) = parseExpression(tokens, tokenCursorCopy) else {
            return .failure("Expression expected but not found")
        }
        expressions.append(expression)
        tokenCursorCopy = newTokenCursorCopy

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

    switch parseInsertValues(tokens, tokenCursorCopy) {
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
