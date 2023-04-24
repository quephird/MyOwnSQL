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

func parseToken(_ tokens: [Token], _ tokenCursor: Int, _ tokenKind: TokenKind) -> ParseHelperResult<Token> {
    if tokenCursor >= tokens.count {
        return .failure("Expected more tokens")
    }

    let currentToken = tokens[tokenCursor]
    if currentToken.kind == tokenKind {
        return .success(tokenCursor+1, currentToken)
    }

    return .noMatch
}

func parseTermExpression(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Expression> {
    if tokenCursor >= tokens.count {
        return .failure("Expected more tokens")
    }

    let maybeTermToken = tokens[tokenCursor]

    switch maybeTermToken.kind {
    // TODO: Consider instead being able to handle tokens
    //       for true and false keywords, and removing the
    //       boolean token type
    case .identifier, .string, .numeric, .boolean:
        return .success(tokenCursor+1, Expression.term(maybeTermToken))
    default:
        return .failure("Term expression not found")
    }
}

func parseExpression(_ tokens: [Token], _ tokenCursor: Int, _ delimeters: [TokenKind], _ minimumBindingPower: Int) -> ParseHelperResult<Expression> {
    var tokenCursorCopy = tokenCursor
    var expression: Expression

    // First we need to see parse an expression, whether it's a term
    // or a binary expression, and possibly enclosed by parentheses
    switch parseToken(tokens, tokenCursorCopy, .symbol(.leftParenthesis)) {
    case .success(let newTokenCursor, _):
        tokenCursorCopy = newTokenCursor

        switch parseExpression(tokens, tokenCursorCopy, delimeters + [TokenKind.symbol(.rightParenthesis)], minimumBindingPower) {
        case .success(let newTokenCursor, let newExpression):
            expression = newExpression
            tokenCursorCopy = newTokenCursor
        default:
            return .failure("Expected expression after parenthesis")
        }

        switch parseToken(tokens, tokenCursorCopy, .symbol(.rightParenthesis)) {
        case .success(let newTokenCursor, _):
            tokenCursorCopy = newTokenCursor
        default:
            return .failure("Expected right parenthesis")
        }
    default:
        switch parseTermExpression(tokens, tokenCursorCopy) {
        case .success(let newTokenCursor, let termExpression):
            expression = termExpression
            tokenCursorCopy = newTokenCursor
        default:
            return .failure("Could not parse expression")
        }
    }

    // OK... now we've got an expression at this point;
    // now we need to see if we've got just a term expression,
    // which will be "terminated" by a delimiting token,
    // such as the FROM or AS keyword, or a binary expression.
    var lastTokenCursor = tokenCursorCopy

outer:
    while tokenCursorCopy < tokens.count {
        // now see if the next token delimits it...
        for delimeter in delimeters {
            if case .success = parseToken(tokens, tokenCursorCopy, delimeter) {
                // It does, so we're done parsing the expression
                break outer
            }
        }

        // If we got here, then we still have some processing to do;
        // check for a binary operator...
        let binaryOperators: [TokenKind] = [
            .keyword(.and),
            .keyword(.or),
            .symbol(.equals),
            .symbol(.notEquals),
            .symbol(.concatenate),
            .symbol(.plus),
            .symbol(.asterisk),
        ]

        var binaryOperator: Token? = nil
        for tokenKind in binaryOperators {
            if case .success(let newTokenCursor, let token) = parseToken(tokens, tokenCursorCopy, tokenKind) {
                tokenCursorCopy = newTokenCursor
                binaryOperator = token
                break
            }
        }

        if binaryOperator == nil {
            return .failure("Expected binary opeator")
        }

        // .. get its binding power and check it against the minimum binding
        // power passed in...
        let operatorBindingPower = bindingPower(binaryOperator!)
        if operatorBindingPower < minimumBindingPower {
            // If we're here, then we encountered an expression like
            // 1 * 2 + 3, where + has lower precedence than *. Moreover,
            // we would only get here if we've recursed at least once
            // and in this example, we'd return 1 * 2 as the left hand
            // expression in the outer call.
            tokenCursorCopy = lastTokenCursor
            break
        }

        // If we're here, then we need to parse the expression on the
        // right hand side of the binary operator parsed just before
        switch parseExpression(tokens, tokenCursorCopy, delimeters, operatorBindingPower) {
        case .success(let newTokenCursor, let newExpression):
            tokenCursorCopy = newTokenCursor
            lastTokenCursor = tokenCursorCopy
            expression = .binary(expression, newExpression, binaryOperator!)
        default:
            return .failure("Expected expression after binary operator")
        }
    }

    return .success(tokenCursorCopy, expression)
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
            let delimiters: [TokenKind] = [.keyword(.from), .keyword(.as), .symbol(.comma)]
            guard case .success(let newTokenCursorCopy, let expression) = parseExpression(tokens, tokenCursorCopy, delimiters, 0) else {
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
    var whereClause: Expression?

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

    var statement = SelectStatement(table, items)

    switch parseToken(tokens, tokenCursorCopy, .keyword(.where)) {
    case .success(let newTokenCursor, _):
        switch parseExpression(tokens, newTokenCursor, [.symbol(.semicolon)], 0) {
        case .success(let newTokenCursor, let expression):
            tokenCursorCopy = newTokenCursor
            whereClause = expression
        default:
            return .failure("Could not parse expression for WHERE clause")
        }
    default:
        whereClause = nil
    }
    statement.whereClause = whereClause

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
        let delimiters: [TokenKind] = [.symbol(.comma), .symbol(.rightParenthesis)]
        guard case .success(let newTokenCursorCopy, let expression) = parseExpression(tokens, tokenCursorCopy, delimiters, 0) else {
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

// For now, the structure of a supported DELETE statement is the following:
//
//     DELETE FROM <table name> <optional WHERE clause>
func parseDeleteStatement(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Statement> {
    var tokenCursorCopy = tokenCursor
    var whereClause: Expression?

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.delete) {
        return .noMatch
    }
    tokenCursorCopy += 1

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.keyword(.from) {
        return .failure("Missing FROM keyword")
    }
    tokenCursorCopy += 1

    guard tokenCursorCopy < tokens.count, case .identifier = tokens[tokenCursorCopy].kind else {
        return .failure("Missing table name")
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    var statement = DeleteStatement(table)

    switch parseToken(tokens, tokenCursorCopy, .keyword(.where)) {
    case .success(let newTokenCursor, _):
        switch parseExpression(tokens, newTokenCursor, [.symbol(.semicolon)], 0) {
        case .success(let newTokenCursor, let expression):
            tokenCursorCopy = newTokenCursor
            whereClause = expression
        default:
            return .failure("Could not parse expression for WHERE clause")
        }
    default:
        whereClause = nil
    }
    statement.whereClause = whereClause

    return .success(tokenCursorCopy, .delete(statement))
}

func parseColumnAssignments(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<[ColumnAssignment]> {
    var tokenCursorCopy = tokenCursor
    var columnAssignments: [ColumnAssignment] = []

    while tokenCursorCopy < tokens.count {
        guard tokenCursorCopy < tokens.count, case .identifier = tokens[tokenCursorCopy].kind else {
            return .failure("Missing column name")
        }
        let columnName = tokens[tokenCursorCopy]
        tokenCursorCopy += 1

        if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.symbol(.equals) {
            return .failure("Missing assignment operator")
        }
        tokenCursorCopy += 1

        let delimiters: [TokenKind] = [.symbol(.comma), .symbol(.rightParenthesis), .keyword(.where)]
        guard case .success(let newTokenCursorCopy, let expression) = parseExpression(tokens, tokenCursorCopy, delimiters, 0) else {
            return .failure("Expression expected but not found")
        }
        columnAssignments.append(ColumnAssignment(columnName, expression))
        tokenCursorCopy = newTokenCursorCopy

        guard tokenCursorCopy < tokens.count, case .symbol(.comma) = tokens[tokenCursorCopy].kind else {
            break
        }
        tokenCursorCopy += 1
    }

    if columnAssignments.isEmpty {
        return .failure("At least one column assignment was expected")
    }
    return .success(tokenCursorCopy, columnAssignments)
}

// For now, the structure of a supported UPDATE statement is the following:
//
//     UPDATE <table name> SET <one or more column assignments separated by a comma> <optional WHERE clause>
func parseUpdateStatement(_ tokens: [Token], _ tokenCursor: Int) -> ParseHelperResult<Statement> {
    var tokenCursorCopy = tokenCursor
    var whereClause: Expression?

    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.update) {
        return .noMatch
    }
    tokenCursorCopy += 1

    guard tokenCursorCopy < tokens.count, case .identifier = tokens[tokenCursorCopy].kind else {
        return .failure("Missing table name")
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    if tokenCursorCopy >= tokens.count || tokens[tokenCursorCopy].kind != TokenKind.keyword(.set) {
        return .failure("Missing SET keyword")
    }
    tokenCursorCopy += 1

    var columnAssignments: [ColumnAssignment]
    switch parseColumnAssignments(tokens, tokenCursorCopy) {
    case .failure(let errorMessage):
        return .failure(errorMessage)
    case .success(let newTokenCursor, let newColumnAssignments):
        tokenCursorCopy = newTokenCursor
        columnAssignments = newColumnAssignments
    default:
        return .failure("Unexpected error occurred")
    }
    var statement = UpdateStatement(table, columnAssignments)

    switch parseToken(tokens, tokenCursorCopy, .keyword(.where)) {
    case .success(let newTokenCursor, _):
        switch parseExpression(tokens, newTokenCursor, [.symbol(.semicolon)], 0) {
        case .success(let newTokenCursor, let expression):
            tokenCursorCopy = newTokenCursor
            whereClause = expression
        default:
            return .failure("Could not parse expression for WHERE clause")
        }
    default:
        whereClause = nil
    }
    statement.whereClause = whereClause

    return .success(tokenCursorCopy, .update(statement))
}

func parseStatement(_ tokens: [Token], _ cursor: Int) -> ParseHelperResult<Statement> {
    let parseHelpers = [
        parseCreateStatement,
        parseInsertStatement,
        parseSelectStatement,
        parseDeleteStatement,
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

func bindingPower(_ token: Token) -> Int {
    switch token.kind {
    case .keyword(let keyword):
        switch keyword {
        case .and, .or:
            return 1
        default:
            return 0
        }
    case .symbol(let symbol):
        switch symbol {
        case .equals, .notEquals:
            return 3
        case .concatenate, .plus:
            return 4
        case .asterisk:
            return 5
        default:
            return 0
        }
    default:
        return 0
    }
}
