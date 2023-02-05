//
//  Parsers.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 2/3/23.
//

func parseExpressions(_ tokens: [Token], _ tokenCursor: Int) -> ([Expression]?, Int, Bool) {
    var tokenCursorCopy = tokenCursor
    var expressions: [Expression] = []

    while tokenCursorCopy < tokens.count {
        let maybeLiteralToken = tokens[tokenCursorCopy]

        switch maybeLiteralToken.kind {
        case .identifier, .string, .numeric:
            let expression = LiteralExpression(literal: maybeLiteralToken)
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

    // loop through tokens starting at current cursor
    //     get current token
    //     if it's one of identifier, string, or numeric, then
    //         create new literal expression for token
    //         add it to expressions
    //     else
    //         return (nil, tokenCursor, false)
    //     end if
    //     increment cursor
    //
    //     get current token
    //     if it's a comma, then
    //         increment cursor and continue
    //     else
    //         break loop
    //     end if
    // end loop
    }

    return (expressions, tokenCursorCopy, true)
}

func parseSelectStatement(_ tokens: [Token], tokenCursor: Int, _ delimiter: Token) -> (SelectStatement?, Int, Bool) {
    var tokenCursorCopy = tokenCursor

    // If current token is the `select` one, then increment token cursor and proceed.
    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.select) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    // Parse expressions next
    let (expressions, newTokenCursor, parsed) = parseExpressions(tokens, tokenCursorCopy)
    if !parsed {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy = newTokenCursor

    // If current token is the `from` one, then increment token cursor and proceed.
    if tokens[tokenCursorCopy].kind != TokenKind.keyword(.from) {
        return (nil, tokenCursor, false)
    }
    tokenCursorCopy += 1

    // If current token is the target table, then increment token cursor and proceed.
    guard case .identifier = tokens[tokenCursorCopy].kind else {
//    if tokens[tokenCursorCopy].kind != .identifier {
        return (nil, tokenCursor, false)
    }
    let table = tokens[tokenCursorCopy]
    tokenCursorCopy += 1

    // Create new SelectStatement
    let statement = SelectStatement(table, expressions!)
    return (statement, tokenCursorCopy, true)
}
