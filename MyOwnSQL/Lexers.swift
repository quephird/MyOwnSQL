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

    while cursorCopy.pointer < source.count {
        let pointerIndex = source.index(source.startIndex, offsetBy: cursorCopy.pointer)
        let char = source[pointerIndex]
        cursorCopy.location.column += 1

        let isDigit = char >= "0" && char <= "9"
        let isPeriod = char == "."
        let isExpMarker = char == "e"

        // Must start with a digit or period
        if cursorCopy.pointer == cursor.pointer {
            if !isDigit && !isPeriod {
                return (nil, cursor, false)
            }

            periodFound = isPeriod
            cursorCopy.pointer += 1
            continue
        }

        if isPeriod {
            // If we found another period, then return
            if periodFound {
                return (nil, cursor, false)
            }

            periodFound = true
            cursorCopy.pointer += 1
            continue
        }

        if isExpMarker {
            expMarkerFound = true

            // No periods allowed after expMarker
            periodFound = true

            // expMarker must not be at the end of the string
            if cursorCopy.pointer == source.count-1 {
                return (nil, cursor, false)
            }

            let nextPointerIndex = source.index(source.startIndex, offsetBy: cursorCopy.pointer+1)
            let nextChar = source[nextPointerIndex]
            // Next character must either be a plus or minus...
            if nextChar == "-" || nextChar == "+" {
                cursorCopy.pointer += 1
                cursorCopy.location.column += 1
            // ... or a digit
            } else if nextChar < "0" || nextChar > "9" {
                return (nil, cursor, false)
            }

            cursorCopy.pointer += 1
            continue
        }

        // If we get here, then from here on out we expect only digits
        if !isDigit {
            break
        }

        cursorCopy.pointer += 1
    }

    // If no characters accumulated, then return
    if cursorCopy.pointer == cursor.pointer {
        return (nil, cursor, false)
    }

    let startIndex = source.index(source.startIndex, offsetBy: cursor.pointer)
    let endIndex = source.index(source.startIndex, offsetBy: cursorCopy.pointer-1)
    let newTokenValue = source[startIndex...endIndex]
    let newToken = Token(value: String(newTokenValue), kind: .numeric, location: cursor.location)
    return (newToken, cursorCopy, true)
}

func lexCharacterDelimited(_ source: String, _ cursor: Cursor, _ delimiter: Character) -> (Token?, Cursor, Bool) {
    var cursorCopy = cursor

    let currentIndex = source.index(source.startIndex, offsetBy: cursorCopy.pointer)
    if source[currentIndex...].count == 0 {
        return (nil, cursor, false)
    }

    if source[currentIndex] != delimiter {
        return (nil, cursor, false)
    }

    cursorCopy.location.column += 1
    cursorCopy.pointer += 1

    var value: String = ""
    while cursorCopy.pointer < source.count {
        let pointerIndex = source.index(source.startIndex, offsetBy: cursorCopy.pointer)
        let char = source[pointerIndex]

        if char == delimiter {
            let nextPointerIndex = source.index(source.startIndex, offsetBy: cursorCopy.pointer+1)

            if cursorCopy.pointer+1 >= source.count || source[nextPointerIndex] != delimiter {
                let newToken = Token(value: value, kind: .string, location: cursor.location)
                return (newToken, cursorCopy, true)
            } else {
                value.append(delimiter)
                cursorCopy.pointer += 1
                cursorCopy.location.column += 1
            }
        }

        value.append(char)
        cursorCopy.pointer += 1
        cursorCopy.location.column += 1
    }

    return (nil, cursor, false)
}

func lexString(_ source: String, _ cursor: Cursor) -> (Token?, Cursor, Bool) {
    return lexCharacterDelimited(source, cursor, "\'")
}

