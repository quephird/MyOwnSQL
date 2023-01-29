//
//  Lexers.swift
//  MyOwnSQL
//
//  Created by Danielle Kefford on 1/5/23.
//

func lexNumeric(_ source: String, _ cursor: Cursor) -> (Token?, Cursor, Bool) {
    var cursorCopy = cursor

    var periodFound = false
    var expMarkerFound = false

CHAR: while cursorCopy.pointer < source.endIndex {
        let char = source[cursorCopy.pointer]
        cursorCopy.location.column += 1

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

            expMarkerFound = true

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

