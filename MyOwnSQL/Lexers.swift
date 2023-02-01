//
//  Lexers.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 1/5/23.
//

func lexNumeric(_ source: String, _ cursor: Cursor) -> (Token?, Cursor, Bool) {
    var cursorCopy = cursor

    var periodFound = false

CHAR: while cursorCopy.pointer < source.endIndex {
        let char = source[cursorCopy.pointer]

        switch char {
        case "0"..."9":
            break

        case ".":
            if periodFound {
                return (nil, cursor, false)
            }

            periodFound = true

        case "e":
            if cursorCopy.pointer == cursor.pointer {
                return (nil, cursor, false)
            }

            // No periods allowed after expMarker
            periodFound = true

            // expMarker must not be at the end of the string
            if cursorCopy.pointer == source.index(before: source.endIndex) {
                return (nil, cursor, false)
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
                return (nil, cursor, false)
            }

        default:
            if cursorCopy.pointer == cursor.pointer {
                return (nil, cursor, false)
            }

            break CHAR
        }

        cursorCopy.location.column += 1
        source.formIndex(after: &cursorCopy.pointer)
    }

    // If no characters accumulated, then return
    if cursorCopy.pointer == cursor.pointer {
        return (nil, cursor, false)
    }

    let newTokenValue = source[cursor.pointer ..< cursorCopy.pointer]
    let newToken = Token(value: String(newTokenValue), kind: .numeric, location: cursor.location)
    return (newToken, cursorCopy, true)
}

func lexCharacterDelimited(_ source: String, _ cursor: Cursor, _ delimiter: Character) -> (Token?, Cursor, Bool) {
    var cursorCopy = cursor

    let currentIndex = cursorCopy.pointer
    if source[currentIndex...].count == 0 {
        return (nil, cursor, false)
    }

    if source[currentIndex] != delimiter {
        return (nil, cursor, false)
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
                let newToken = Token(value: value, kind: .string, location: cursor.location)
                return (newToken, cursorCopy, true)
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

    return (nil, cursor, false)
}

func lexString(_ source: String, _ cursor: Cursor) -> (Token?, Cursor, Bool) {
    return lexCharacterDelimited(source, cursor, "\'")
}

func longestMatch(_ source: String, _ cursor: Cursor, _ options: [String]) -> String? {
    return options.filter { option in
        // TODO: Is this the best way to support case insensitivity?
        source[cursor.pointer ..< source.endIndex].hasPrefix(option)
    }.sorted(by: { (match1, match2) in
        match1.count > match2.count
    }).first
}

func lexSymbol(_ source: String, _ cursor: Cursor) -> (Token?, Cursor, Bool) {
    var cursorCopy = cursor

    switch source[cursor.pointer] {
    // Syntax that should be thrown away
    case "\n":
        source.formIndex(after: &cursorCopy.pointer)
        cursorCopy.location.line += 1
        cursorCopy.location.column = 0
        return (nil, cursorCopy, true)
    case "\t", " ":
        source.formIndex(after: &cursorCopy.pointer)
        cursorCopy.location.column += 1
        return (nil, cursorCopy, true)
    // Syntax that should be kept
    default:
        let allSymbols: [String] = [
            Symbol.semicolon,
            Symbol.asterisk,
            Symbol.comma,
            Symbol.leftParenthesis,
            Symbol.rightParenthesis,
        ].map { symbol in
            symbol.rawValue
        }

        if let match = longestMatch(source, cursor, allSymbols) {
            source.formIndex(&cursorCopy.pointer, offsetBy: match.count)
            cursorCopy.location.column += match.count

            let newToken = Token(value: match, kind: .symbol, location: cursor.location)
            return (newToken, cursorCopy, true)
        } else {
            return (nil, cursor, false)
        }
    }
}

func lexKeyword(_ source: String, _ cursor: Cursor) -> (Token?, Cursor, Bool) {
    var cursorCopy = cursor

    let allKeywords = Keyword.allCases.map { keyword in
        keyword.rawValue
    }

    if let match = longestMatch(source.lowercased(), cursor, allKeywords) {
        source.formIndex(&cursorCopy.pointer, offsetBy: match.count)
        cursorCopy.location.column += match.count

        let newToken = Token(value: match, kind: .keyword, location: cursor.location)
        return (newToken, cursorCopy, true)
    } else {
        return (nil, cursor, false)
    }
}

func lexIdentifier(_ source: String, _ cursor: Cursor) -> (Token?, Cursor, Bool) {
    switch lexCharacterDelimited(source, cursor, "\"") {
    // Handle separately if is a double-quoted identifier
    case (var token?, let newCursor, true):
        // lexCharacterDelimited() currently returns a token with a string type,
        // so we need to update it here.
        token.kind = .identifier
        return (token, newCursor, true)
    default:
        var cursorCopy = cursor

        switch source[cursorCopy.pointer] {
        case "A"..."Z", "a"..."z":
            var value: String = ""
            while cursorCopy.pointer < source.endIndex {
                let char = source[cursorCopy.pointer]
                switch char {
                case "A"..."Z", "a"..."z", "0"..."9", "$", "_":
                    value.append(char)
                    source.formIndex(after: &cursorCopy.pointer)
                    cursorCopy.location.column += 1
                default:
                    break
                }
            }

            if value.count == 0 {
                return (nil, cursor, false)
            } else {
                let newToken = Token(value: value, kind: .identifier, location: cursor.location)
                return (newToken, cursorCopy, true)
            }
        default:
            return (nil, cursor, false)
        }
    }
}
