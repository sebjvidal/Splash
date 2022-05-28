/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation
import Swift
import XCTest

/// Grammar for the Swift language. Use this implementation when
/// highlighting Swift code. This is the default grammar.
public struct CssGrammar: Grammar {
    public var delimiters: CharacterSet
    public var syntaxRules: [SyntaxRule]
    
    public init() {
        var delimiters = CharacterSet.alphanumerics.inverted
        delimiters.remove("_")
        delimiters.remove("-")
        delimiters.remove("\"")
        delimiters.remove("'")
        delimiters.remove("#")
        delimiters.remove("@")
        delimiters.remove("$")
        delimiters.remove("%")
        self.delimiters = delimiters
        
        syntaxRules = [
            UrlRule(),
            CommentRule(),
            SingleLineStringRule(),
            NumberRule(),
            PropertyRule(),
            DeclarationRule(),
            CallRule(),
            OtherRule()
        ]
    }
    
    public func isDelimiter(_ delimiterA: Character,
                            mergableWith delimiterB: Character) -> Bool {
        switch (delimiterA, delimiterB) {
        case ("\\", "("):
            return true
        case ("\\", _), (_, "\\"):
            return false
        case (")", _):
            return false
        case ("/", "/"), ("/", "*"), ("*", "/"):
            return true
        case ("/", _):
            return false
        case ("(", _) where delimiterB != ".":
            return false
        case (".", "/"), (",", "/"):
            return false
        case ("{", "/"), ("}", "/"):
            return false
        case ("[", "/"), ("]", "/"):
            return false
        case (">", "/"), ("?", "/"):
            return false
        case ("-", _) where delimiterB.isASCII:
            return true
        default:
            return true
        }
    }
}

private extension CssGrammar {
    struct CommentRule: SyntaxRule {
        var tokenType: TokenType { return .comment }
        
        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("/*") {
                if segment.tokens.current.hasSuffix("*/") {
                    return true
                }
            }
            
            if segment.tokens.current.hasPrefix("//") {
                return true
            }
            
            if segment.tokens.onSameLine.contains(anyOf: "//", "///") {
                return true
            }
            
            if segment.tokens.current.isAny(of: "/*", "/**", "*/") {
                return true
            }
            
            let multiLineStartCount = segment.tokens.count(of: "/*") + segment.tokens.count(of: "/**")
            return multiLineStartCount != segment.tokens.count(of: "*/")
        }
    }
    
    struct UrlRule: SyntaxRule {
        var tokenType: TokenType { return .url }
        
        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.isAny(of: "*", "/*", "/**", "**/", "*/", "//", "///") {
                return false
            }
            
            if !segment.isWithinComment {
                return false
            }
            
            if segment.tokens.current.isAny(of: "http", "https") && segment.tokens.next.isAny(of: "://") {
                return true
            }
            
            if segment.tokens.current.isAny(of: "://") && segment.tokens.previous.isAny(of: "http", "https") {
                return true
            }
            
            if let url = String(segment.prefix).components(separatedBy: " ").last { // Seperator not working
                if url.hasPrefix("http://") || url.hasPrefix("https://") {
                    return true
                }
            }
            
            return false
        }
    }
    
    struct SingleLineStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }
        
        func matches(_ segment: Segment) -> Bool {
            if (segment.tokens.current.hasPrefix("\"") &&
                segment.tokens.current.hasSuffix("\"")) ||
                segment.tokens.current.hasPrefix("'") &&
                segment.tokens.current.hasSuffix("'"){
                return true
            }
            
            guard segment.isWithinStringLiteral(withStart: "\"", end: "\"") ||
                    segment.isWithinStringLiteral(withStart: "'", end: "'")else {
                return false
            }
            
            return !segment.isWithinStringInterpolation &&
            !segment.isWithinRawStringInterpolation
        }
    }
    
    struct NumberRule: SyntaxRule {
        var tokenType: TokenType { return .number }
        
        func matches(_ segment: Segment) -> Bool {
            // Don't match against index-based closure arguments
            if let previous = segment.tokens.previous {
                guard !previous.hasSuffix("$") else {
                    return false
                }
            }
            
            // Integers can be separated using "_", so handle that
            if segment.tokens.current.removing("_").removing("px").removing("%").isNumber {
                return true
            }
            
            // Double and floating point values that contain a "."
            guard segment.tokens.current == "." else {
                return false
            }
            
            guard let previous = segment.tokens.previous,
                  let next = segment.tokens.next else {
                return false
            }
            
            return (previous.isNumber && next.isNumber)
        }
    }

    struct DeclarationRule: SyntaxRule {
        var tokenType: TokenType { return .otherDeclaration }
        
        func matches(_ segment: Segment) -> Bool {
            guard segment.tokens.current.removing("#").removing("@").isAlphanumericDash else {
                return false
            }
            
            guard !segment.tokens.next.isAny(of: ";") else {
                return false
            }
            
            guard !segment.isWithinBraces else {
                return false
            }
            
            return true
        }
    }
    
    struct PropertyRule: SyntaxRule {
        var tokenType: TokenType { return .declaration }
        
        func matches(_ segment: Segment) -> Bool {
            print(segment.tokens.current)
            guard segment.tokens.current.isAlphanumericDash else {
                return false
            }
            
            guard segment.tokens.next.isAny(of: ":") else {
                return false
            }

            return segment.tokens.previous.isAny(of: ";", "{")//[";", "{"].contains(segment.tokens.previous!)
        }
    }
    
    struct CallRule: SyntaxRule {
        var tokenType: TokenType { return .call }
        
        func matches(_ segment: Segment) -> Bool {
            guard !segment.tokens.current.isCapitalized else {
                return false
            }
            
            guard segment.tokens.next.isAny(of: "(") else {
                return false
            }
            
            guard segment.tokens.current.isAlphanumericDash else {
                return false
            }
            
            return true
        }
    }
    
    struct OtherRule: SyntaxRule {
        var tokenType: TokenType { return .otherType }
        
        func matches(_ segment: Segment) -> Bool {
            guard segment.tokens.onSameLine.contains(":") else {
                return false
            }
            
            guard segment.tokens.current.removing("#").isAlphanumericDash else {
                return false
            }
            
            return true
        }
    }
}

private extension Segment {
    func isWithinStringLiteral(withStart start: String, end: String) -> Bool {
        if tokens.current.hasPrefix(start) {
            return true
        }
        
        if tokens.current.hasSuffix(end) {
            return true
        }
        
        var markerCounts = (start: 0, end: 0)
        var previousToken: String?
        
        for token in tokens.onSameLine {
            if token.hasPrefix("(") || token.hasPrefix("#(") || token.hasPrefix("\"") || token.hasPrefix("'") {
                guard previousToken != "\\" else {
                    previousToken = token
                    continue
                }
            }
            
            if token == start {
                if start != end || markerCounts.start == markerCounts.end {
                    markerCounts.start += 1
                } else {
                    markerCounts.end += 1
                }
            } else if token == end && start != end {
                markerCounts.end += 1
            } else {
                if token.hasPrefix(start) {
                    markerCounts.start += 1
                }
                
                if token.hasSuffix(end) {
                    markerCounts.end += 1
                }
            }
            
            previousToken = token
        }
        
        return markerCounts.start != markerCounts.end
    }
    
    var isWithinStringInterpolation: Bool {
        let delimiter = "\\("
        
        if tokens.current == delimiter || tokens.previous == delimiter {
            return true
        }
        
        let components = tokens.onSameLine.split(separator: delimiter)
        
        guard components.count > 1 else {
            return false
        }
        
        let suffix = components.last!
        var paranthesisCount = 1
        
        for component in suffix {
            paranthesisCount += component.numberOfOccurrences(of: "(")
            paranthesisCount -= component.numberOfOccurrences(of: ")")
            
            guard paranthesisCount > 0 else {
                return false
            }
        }
        
        return true
    }
    
    var isWithinBraces: Bool {
        let delimiter = "{"
        
        if tokens.current == delimiter || tokens.previous == delimiter {
            return true
        }
        
        let components = tokens.onSameLine.split(separator: delimiter)
        
        guard components.count > 1 else {
            return false
        }
        
        let suffix = components.last!
        var paranthesisCount = 1
        
        for component in suffix {
            paranthesisCount += component.numberOfOccurrences(of: "{")
            paranthesisCount -= component.numberOfOccurrences(of: "}")
            
            guard paranthesisCount > 0 else {
                return false
            }
        }
        
        return true
    }
    
    var isWithinRawStringInterpolation: Bool {
        // Quick fix for supporting single expressions within raw string
        // interpolation, a proper fix should be developed ASAP.
        switch tokens.current {
        case "\\":
            return tokens.previous != "\\" && tokens.next == "#"
        case "#":
            return tokens.previous == "\\" && tokens.next == "("
        case "(":
            return tokens.onSameLine.suffix(2) == ["\\", "#"]
        case ")":
            let suffix = tokens.onSameLine.suffix(4)
            return suffix.prefix(3) == ["\\", "#", "("]
        default:
            let suffix = tokens.onSameLine.suffix(3)
            return suffix == ["\\", "#", "("] && tokens.next == ")"
        }
    }
    
    var isWithinComment: Bool {
        if tokens.current.hasPrefix("/*") {
            if tokens.current.hasSuffix("*/") {
                return true
            }
        }
        
        if tokens.current.hasPrefix("//") {
            return true
        }
        
        if tokens.onSameLine.contains(anyOf: "//", "///") {
            return true
        }
        
        if tokens.current.isAny(of: "/*", "/**", "*/") {
            return true
        }
        
        let multiLineStartCount = tokens.count(of: "/*") + tokens.count(of: "/**")
        return multiLineStartCount != tokens.count(of: "*/")
    }
    
    var prefixedByDotAccess: Bool {
        return tokens.previous == "(." || prefix.hasSuffix(" .")
    }
    
    var isValidSymbol: Bool {
        guard let firstCharacter = tokens.current.first else {
            return false
        }
        
        return firstCharacter == "_" || firstCharacter == "$" || firstCharacter.isLetter
    }
}
