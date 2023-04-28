//
//  Lexers.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 1/5/23.
//

enum LexHelperResult: Equatable {
    case failure
    case success(Cursor, Token?)
}

func lexNumeric(_ source: String, _ cursor: Cursor) -> LexHelperResult {
    var cursorCopy = cursor

    var periodFound = false

CHAR: while cursorCopy.pointer < source.endIndex {
        let char = source[cursorCopy.pointer]

        switch char {
        case "0"..."9":
            break

        case ".":
            if periodFound {
                return .failure
            }

            periodFound = true

        case "e":
            if cursorCopy.pointer == cursor.pointer {
                return .failure
            }

            // No periods allowed after expMarker
            periodFound = true

            // expMarker must not be at the end of the string
            if cursorCopy.pointer == source.index(before: source.endIndex) {
                return .failure
            }

            let nextPointerIndex = source.index(after: cursorCopy.pointer)
            switch source[nextPointerIndex] {
            // Next character must either be a plus or minus...
            case "-", "+":
                source.formIndex(after: &cursorCopy.pointer)
                cursorCopy.location.column += 1
            // ... or a digit
            case "0"..."9":
                break
            default:
                return .failure
            }

        default:
            if cursorCopy.pointer == cursor.pointer {
                return .failure
            }

            break CHAR
        }

        cursorCopy.location.column += 1
        source.formIndex(after: &cursorCopy.pointer)
    }

    // If no characters accumulated, then return
    if cursorCopy.pointer == cursor.pointer {
        return .failure
    }

    let newTokenValue = source[cursor.pointer ..< cursorCopy.pointer]
    let newToken = Token(kind: .numeric(String(newTokenValue)), location: cursor.location)
    return .success(cursorCopy, newToken)
}

func lexCharacterDelimited(_ source: String, _ cursor: Cursor, _ delimiter: Character) -> LexHelperResult {
    var cursorCopy = cursor

    let currentIndex = cursorCopy.pointer
    if source[currentIndex...].count == 0 {
        return .failure
    }

    if source[currentIndex] != delimiter {
        return .failure
    }

    cursorCopy.location.column += 1
    source.formIndex(after: &cursorCopy.pointer)

    var value: String = ""
    while cursorCopy.pointer < source.endIndex {
        let pointerIndex = cursorCopy.pointer
        let char = source[pointerIndex]

        if char == delimiter {
            let nextPointerIndex = source.index(after: cursorCopy.pointer)

            if nextPointerIndex >= source.endIndex || source[nextPointerIndex] != delimiter {
                source.formIndex(after: &cursorCopy.pointer)
                cursorCopy.location.column += 1
                let newToken = Token(kind: .string(value), location: cursor.location)
                return .success(cursorCopy, newToken)
            } else {
                value.append(delimiter)
                source.formIndex(after: &cursorCopy.pointer)
                cursorCopy.location.column += 1
            }
        }

        value.append(char)
        source.formIndex(after: &cursorCopy.pointer)
        cursorCopy.location.column += 1
    }

    return .failure
}

func lexString(_ source: String, _ cursor: Cursor) -> LexHelperResult {
    return lexCharacterDelimited(source, cursor, "\'")
}

extension RawRepresentable where RawValue == String, Self: CaseIterable {
    static func longestMatch(_ source: String, _ cursor: Cursor) -> Self? {
        return self.allCases.filter { option in
            source[cursor.pointer ..< source.endIndex].hasPrefix(option.rawValue)
        }.sorted(by: { (match1, match2) in
            match1.rawValue.count > match2.rawValue.count
        }).first
    }
}

func lexSymbol(_ source: String, _ cursor: Cursor) -> LexHelperResult {
    var cursorCopy = cursor

    // TODO: Think about moving whitespace lexing to separate lexer function
    switch source[cursor.pointer] {
    // Syntax that should be thrown away
    case "\n":
        source.formIndex(after: &cursorCopy.pointer)
        cursorCopy.location.line += 1
        cursorCopy.location.column = 0
        return .success(cursorCopy, nil)
    case "\t", " ":
        source.formIndex(after: &cursorCopy.pointer)
        cursorCopy.location.column += 1
        return .success(cursorCopy, nil)
    // Syntax that should be kept
    default:
        if let match = Symbol.longestMatch(source, cursor) {
            source.formIndex(&cursorCopy.pointer, offsetBy: match.rawValue.count)
            cursorCopy.location.column += match.rawValue.count

            let newToken = Token(kind: .symbol(match), location: cursor.location)
            return .success(cursorCopy, newToken)
        } else {
            return .failure
        }
    }
}

func lexKeyword(_ source: String, _ cursor: Cursor) -> LexHelperResult {
    var cursorCopy = cursor
    var maybeKeyword = ""

    // Keywords _must_ be delimited by either whitespace or other punctuation characters
OUTER:
    for char in source[cursor.pointer..<source.endIndex] {
        switch char {
        case "\n", "\t", " ", "(", ")", ";", ",":
            break OUTER
        default:
            maybeKeyword.append(char)
        }
    }

    if maybeKeyword == "" {
        return .failure
    }

    for keyword in Keyword.allCases {
        if keyword.rawValue == maybeKeyword.lowercased() {
            source.formIndex(&cursorCopy.pointer, offsetBy: maybeKeyword.count)

            var newToken = Token(kind: .keyword(keyword), location: cursor.location)
            if [Keyword.true, Keyword.false].contains(keyword) {
                newToken.kind = .boolean(maybeKeyword)
            }

            cursorCopy.location.column += maybeKeyword.count
            return .success(cursorCopy, newToken)
        }
    }

    return .failure
}

func lexIdentifier(_ source: String, _ cursor: Cursor) -> LexHelperResult {
    switch lexCharacterDelimited(source, cursor, "\"") {
    // Handle separately if is a double-quoted identifier
    case .success(let newCursor, var token?):
        // TODO: This is a bit hacky
        // lexCharacterDelimited() currently returns a token with a string type,
        // so we need to update it here. Maybe make lexCharacterDelimited()
        // return the parsed string instead?
        guard case .string(let str) = token.kind else { fatalError() }
        token.kind = .identifier(str)
        return .success(newCursor, token)
    case .success(_, nil):
        fatalError()
    case .failure:
        var cursorCopy = cursor

        switch source[cursorCopy.pointer] {
        case "A"..."Z", "a"..."z":
            var value: String = ""
LEX:        while cursorCopy.pointer < source.endIndex {
                let char = source[cursorCopy.pointer]
                switch char {
                case "A"..."Z", "a"..."z", "0"..."9", "$", "_":
                    value.append(char)
                    source.formIndex(after: &cursorCopy.pointer)
                    cursorCopy.location.column += 1
                default:
                    break LEX
                }
            }

            if value.count == 0 {
                return .failure
            } else {
                let newToken = Token(kind: .identifier(value), location: cursor.location)
                return .success(cursorCopy, newToken)
            }
        default:
            return .failure
        }
    }
}

enum LexResult: Equatable {
    case failure(String)
    case success([Token])
}

func lex(_ source: String) -> LexResult {
    var tokens: [Token] = []
    let location = Location(line: 0, column: 0)
    var cursor = Cursor(pointer: source.startIndex, location: location)

LEX:
    while cursor.pointer < source.endIndex {
        let lexers = [lexKeyword, lexSymbol, lexString, lexNumeric, lexIdentifier]
        for lexer in lexers {
            switch lexer(source, cursor) {
            case .success(let newCursor, let maybeToken):
                cursor = newCursor

                if let token = maybeToken {
                    tokens.append(token)
                }

                continue LEX
            case .failure:
                continue
            }
        }

        var hint = ""
        if tokens.count > 0 {
            hint = " after " + tokens[tokens.count-1].kind.description
        }

        let errorMessage = "Unable to lex token\(hint), at line \(cursor.location.line), column \(cursor.location.column)"
        return .failure(errorMessage)
    }

    return .success(tokens)
}
