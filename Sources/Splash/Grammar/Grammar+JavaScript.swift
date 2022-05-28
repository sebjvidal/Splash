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
public struct JavaScriptGrammar: Grammar {
    public var delimiters: CharacterSet
    public var syntaxRules: [SyntaxRule]
    
    public init() {
        var delimiters = CharacterSet.alphanumerics.inverted
        delimiters.remove("_")
        delimiters.remove("\"")
        delimiters.remove("`")
        delimiters.remove("'")
        delimiters.remove("#")
        delimiters.remove("@")
        delimiters.remove("$")
        self.delimiters = delimiters
        
        syntaxRules = [
            UrlRule(),
            CommentRule(),
            MultiLineStringRule(),
            SingleLineStringRule(),
            AttributeRule(),
            NumberRule(),
            TypeRule(),
            OtherTypeRule(),
            CallRule(),
            OtherCallRule(),
            PropertyRule(),
            DotAccessRule(),
            KeywordRule(),
            DeclarationRule(),
            OtherDeclarationRule(),
            ParameterRule()
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
        default:
            return true
        }
    }
}

private extension JavaScriptGrammar {
    static let keywords = ([
        "abstract", "arguments", "await", "boolean",
        "break", "byte", "case", "catch", "char", "class",
        "const", "continue", "debugger", "default", "delete",
        "do", "double", "else", "enum", "eval", "export",
        "extends", "false", "final", "finally", "float",
        "for", "function", "goto", "if", "implements", "import",
        "in", "instanceof", "int", "interface", "let", "long",
        "native", "new", "null", "package", "private",
        "protected", "public", "return", "short", "static",
        "super", "switch", "synchronized", "this", "throw",
        "throws", "transient", "true", "try", "typeof", "var",
        "void", "volatile", "while", "with", "yield"
    ] as Set<String>).union(accessControlKeywords)
    
    static let accessControlKeywords: Set<String> = [
        "public", "private"
    ]
    
    static let declarationKeywords: Set<String> = [
        "class", "enum", "interface"
    ]
    
    static let builtInTypes: Set<String> = [
        
    ]
    
    static let builtInFunctions: Set<String> = []
    
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
    
    struct AttributeRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }
        
        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("@") {
                return true
            }
            
            if segment.tokens.previous == "." {
                let suffix = segment.tokens.onSameLine.suffix(2)
                
                guard suffix.count == 2 else {
                    return false
                }
                
                return suffix.first?.hasPrefix("@") ?? false
            }
            
            return false
        }
    }
    
    struct MultiLineStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }
        
        func matches(_ segment: Segment) -> Bool {
            guard !segment.tokens.count(of: "\"\"\"").isEven ||
                    !segment.tokens.count(of: "`").isEven else {
                return false
            }
            
            return !segment.isWithinStringInterpolation
        }
    }
    
    struct SingleLineStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }
        
        func matches(_ segment: Segment) -> Bool {
            if (segment.tokens.current.hasPrefix("\"") &&
                segment.tokens.current.hasSuffix("\"")) ||
                (segment.tokens.current.hasPrefix("`") &&
                 segment.tokens.current.hasSuffix("`")) ||
                (segment.tokens.current.hasPrefix("'") &&
                 segment.tokens.current.hasSuffix("'")) {
                return true
            }
            
            guard segment.isWithinStringLiteral(withStart: "\"", end: "\"") ||
                    segment.isWithinStringLiteral(withStart: "`", end: "`") ||
                    segment.isWithinStringLiteral(withStart: "'", end: "'")  else {
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
            if segment.tokens.current.removing("_").isNumber {
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
            
            return previous.isNumber && next.isNumber
        }
    }
    
    struct CallRule: SyntaxRule {
        var tokenType: TokenType { return .type }
        private let keywordsToAvoid: Set<String>
        private let callLikeKeywords: Set<String>
        private let controlFlowTokens = ["if", "&&", "||", "for", "switch"]
        
        init() {
            var keywordsToAvoid = keywords
            keywordsToAvoid.remove("return")
            keywordsToAvoid.remove("try")
            keywordsToAvoid.remove("throw")
            keywordsToAvoid.remove("if")
            keywordsToAvoid.remove("in")
            keywordsToAvoid.remove("await")
            keywordsToAvoid.remove("this")
            keywordsToAvoid.remove("true")
            keywordsToAvoid.remove("false")
            keywordsToAvoid.remove("null")
            self.keywordsToAvoid = keywordsToAvoid
            
            let callLikeKeywords = accessControlKeywords
            self.callLikeKeywords = callLikeKeywords
        }
        
        func matches(_ segment: Segment) -> Bool {
            guard segment.tokens.current.isAny(of: builtInFunctions) else {
                return false
            }
            
            guard !segment.tokens.previous.isAny(of: ".") else {
                return false
            }
            
            let token = segment.tokens.current.trimmingCharacters(
                in: CharacterSet(charactersIn: "_")
            )
            
            guard token.startsWithLetter else {
                return false
            }
            
            // Never highlight initializers as regular function calls
            if token == "init" {
                return false
            }
            
            // There's a few keywords that might look like function calls
            if callLikeKeywords.contains(segment.tokens.current) {
                if let nextToken = segment.tokens.next {
                    guard !nextToken.starts(with: "(") else {
                        return false
                    }
                }
            }
            
            if let previousToken = segment.tokens.previous {
                guard !keywordsToAvoid.contains(previousToken) else {
                    return false
                }
                
                // Don't treat enums with associated values as function calls
                // when they appear within a switch statement
                if previousToken == "." {
                    let previousTokens = segment.tokens.onSameLine
                    
                    if previousTokens.count > 1 {
                        let lastToken = previousTokens[previousTokens.count - 2]
                        
                        guard lastToken != "case" else {
                            return false
                        }
                        
                        // Multiple expressions can be matched within a single case
                        guard !lastToken.hasSuffix(",") else {
                            return false
                        }
                    }
                }
            }
            
            // Handle trailing closure syntax
            guard segment.trailingWhitespace == nil else {
                guard segment.tokens.next.isAny(of: "{", "{}") else {
                    return false
                }
                
                if segment.tokens.previous != "." || segment.tokens.onSameLine.isEmpty {
                    guard !keywords.contains(segment.tokens.current) else {
                        return false
                    }
                }
                
                guard !segment.tokens.onSameLine.contains(anyOf: declarationKeywords) else {
                    return false
                }
                
                return !segment.tokens.onSameLine.contains(anyOf: controlFlowTokens)
                
            }
            
            return segment.tokens.next?.starts(with: "(") ?? false
        }
    }
    
    struct OtherCallRule: SyntaxRule {
        var tokenType: TokenType { return .call }
        private let keywordsToAvoid: Set<String>
        private let callLikeKeywords: Set<String>
        private let controlFlowTokens = ["if", "&&", "||", "for", "switch"]
        
        init() {
            var keywordsToAvoid = keywords
            keywordsToAvoid.remove("return")
            keywordsToAvoid.remove("try")
            keywordsToAvoid.remove("throw")
            keywordsToAvoid.remove("if")
            keywordsToAvoid.remove("in")
            keywordsToAvoid.remove("await")
            keywordsToAvoid.remove("self")
            keywordsToAvoid.remove("true")
            keywordsToAvoid.remove("false")
            keywordsToAvoid.remove("nil")
            self.keywordsToAvoid = keywordsToAvoid
            
            var callLikeKeywords = accessControlKeywords
            callLikeKeywords.insert("subscript")
            callLikeKeywords.insert("init")
            self.callLikeKeywords = callLikeKeywords
        }
        
        func matches(_ segment: Segment) -> Bool {
            guard !segment.tokens.current.isAny(of: builtInFunctions) else {
                return false
            }
            
            let token = segment.tokens.current.trimmingCharacters(
                in: CharacterSet(charactersIn: "_")
            )
            
            guard token.startsWithLetter else {
                return false
            }
            
            // Never highlight initializers as regular function calls
            if token == "init" {
                return false
            }
            
            // There's a few keywords that might look like function calls
            if callLikeKeywords.contains(segment.tokens.current) {
                if let nextToken = segment.tokens.next {
                    guard !nextToken.starts(with: "(") else {
                        return false
                    }
                }
            }
            
            if let previousToken = segment.tokens.previous {
                guard !keywordsToAvoid.contains(previousToken) else {
                    return false
                }
                
                // Don't treat enums with associated values as function calls
                // when they appear within a switch statement
                if previousToken == "." {
                    let previousTokens = segment.tokens.onSameLine
                    
                    if previousTokens.count > 1 {
                        let lastToken = previousTokens[previousTokens.count - 2]
                        
                        guard lastToken != "case" else {
                            return false
                        }
                        
                        // Multiple expressions can be matched within a single case
                        guard !lastToken.hasSuffix(",") else {
                            return false
                        }
                    }
                }
            }
            
            // Handle trailing closure syntax
            guard segment.trailingWhitespace == nil else {
                guard segment.tokens.next.isAny(of: "{", "{}") else {
                    return false
                }
                
                if segment.tokens.previous != "." || segment.tokens.onSameLine.isEmpty {
                    guard !keywords.contains(segment.tokens.current) else {
                        return false
                    }
                }
                
                guard !segment.tokens.onSameLine.contains(anyOf: declarationKeywords) else {
                    return false
                }
                
                return !segment.tokens.onSameLine.contains(anyOf: controlFlowTokens)
                
            }
            
            return segment.tokens.next?.starts(with: "(") ?? false
        }
    }
    
    struct KeywordRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }
        
        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current == "prefix" && segment.tokens.next == "function" {
                return true
            }
            
            if segment.tokens.current == "some" {
                guard segment.tokens.previous != "case" else {
                    return false
                }
            }
            
            if segment.tokens.next == ":", segment.tokens.current != "nil" {
                guard segment.tokens.current == "default" else {
                    return false
                }
            }
            
            if segment.trailingWhitespace == nil {
                if !segment.tokens.current.isAny(of: "self", "super") {
                    guard segment.tokens.next != "." else {
                        return false
                    }
                }
            }
            
            if let previousToken = segment.tokens.previous {
                if !segment.tokens.onSameLine.isEmpty {
                    // Don't highlight variables with the same name as a keyword
                    // when used in optional binding, such as if let, guard let:
                    if segment.tokens.current != "self" {
                        guard !previousToken.isAny(of: "let", "var") else {
                            return false
                        }
                        
                        if segment.tokens.current == "actor" {
                            if accessControlKeywords.contains(previousToken) {
                                return true
                            }
                            
                            return previousToken.first == "@"
                        }
                    }
                }
                
                if !declarationKeywords.contains(segment.tokens.current) {
                    // Highlight the '(set)' part of setter access modifiers
                    switch segment.tokens.current {
                    case "(":
                        return accessControlKeywords.contains(previousToken)
                    case "set":
                        if previousToken == "(" {
                            return true
                        }
                    case ")":
                        return previousToken == "set"
                    default:
                        break
                    }
                    
                    // Don't highlight most keywords when used as a parameter label
                    if !segment.tokens.current.isAny(of: "self", "let", "var", "true", "false", "inout", "nil", "try", "actor") {
                        guard !previousToken.isAny(of: "(", ",", ">(") else {
                            return false
                        }
                    }
                    
                    guard !segment.tokens.previous.isAny(of: "function", "`") else {
                        return false
                    }
                }
            }
            
            return keywords.contains(segment.tokens.current)
        }
    }
    
    struct TypeRule: SyntaxRule {
        var tokenType: TokenType { return .type }
        
        func matches(_ segment: Segment) -> Bool {
            // Types should not be highlighted when declared
            
            if let previousToken = segment.tokens.previous {
                guard !previousToken.isAny(of: declarationKeywords) else {
                    return false
                }
                
                // Types should not be highlighted if a declarative keyword leads
                guard !segment.tokens.onSameLine.contains(anyOf: declarationKeywords) else {
                    return false
                }
            }
            
            let token = segment.tokens.current.trimmingCharacters(
                in: CharacterSet(charactersIn: "_")
            )
            
            guard token.isAny(of: builtInTypes) else {
                return false
            }
            
            guard token.isCapitalized else {
                return false
            }
            
            guard !segment.prefixedByDotAccess else {
                return false
            }
            
            // The XCTAssert family of functions is a bit of an edge case,
            // since they start with capital letters. Since they are so
            // commonly used, we'll add a special case for them here:
            guard !token.starts(with: "XCTAssert") else {
                return false
            }
            
            // In a generic declaration, only highlight constraints
            if segment.tokens.previous.isAny(of: "<", ",", "*/") {
                var foundOpeningBracket = false
                
                // Since the declaration might be on another line, we have to walk
                // backwards through all tokens until we've found enough information.
                for token in segment.tokens.all.reversed() {
                    // Highlight return type generics as normal
                    if token.isAny(of: "->", ">", ">:") {
                        return true
                    }
                    
                    if !foundOpeningBracket && token == "<" {
                        foundOpeningBracket = true
                    }
                    
                    // Handling generic lists for parameters, rather than declarations
                    if foundOpeningBracket {
                        if token == ":" || token.first == "@" {
                            return true
                        }
                    }
                    
                    guard !declarationKeywords.contains(token) else {
                        // If it turns out that we weren't in fact inside of a generic
                        // declaration, (lacking "<"), then highlight the type as normal.
                        return !foundOpeningBracket
                    }
                    
                    if token.isAny(of: "=", "==", "(", "_", "@escaping") {
                        return true
                    }
                }
            }
            
            return true
        }
    }
    
    struct OtherTypeRule: SyntaxRule {
        var tokenType: TokenType { return .otherType }
        
        func matches(_ segment: Segment) -> Bool {
            // Types should not be highlighted when declared
            
            if let previousToken = segment.tokens.previous {
                guard !previousToken.isAny(of: declarationKeywords) else {
                    return false
                }
                
                // Types should not be highlighted if a declarative keyword leads
                guard !segment.tokens.onSameLine.contains(anyOf: declarationKeywords) else {
                    return false
                }
            }
            
            let token = segment.tokens.current.trimmingCharacters(
                in: CharacterSet(charactersIn: "_")
            )
            
            guard !token.isAny(of: builtInTypes) else {
                return false
            }
            
            guard token.isCapitalized else {
                return false
            }
            
            guard !segment.prefixedByDotAccess else {
                return false
            }
            
            // The XCTAssert family of functions is a bit of an edge case,
            // since they start with capital letters. Since they are so
            // commonly used, we'll add a special case for them here:
            guard !token.starts(with: "XCTAssert") else {
                return false
            }
            
            // In a generic declaration, only highlight constraints
            if segment.tokens.previous.isAny(of: "<", ",", "*/") {
                var foundOpeningBracket = false
                
                // Since the declaration might be on another line, we have to walk
                // backwards through all tokens until we've found enough information.
                for token in segment.tokens.all.reversed() {
                    // Highlight return type generics as normal
                    if token.isAny(of: "->", ">", ">:") {
                        return true
                    }
                    
                    if !foundOpeningBracket && token == "<" {
                        foundOpeningBracket = true
                    }
                    
                    // Handling generic lists for parameters, rather than declarations
                    if foundOpeningBracket {
                        if token == ":" || token.first == "@" {
                            return true
                        }
                    }
                    
                    guard !declarationKeywords.contains(token) else {
                        // If it turns out that we weren't in fact inside of a generic
                        // declaration, (lacking "<"), then highlight the type as normal.
                        return !foundOpeningBracket
                    }
                    
                    if token.isAny(of: "=", "==", "(", "_", "@escaping") {
                        return true
                    }
                }
            }
            
            return true
        }
    }
    
    struct DotAccessRule: SyntaxRule {
        var tokenType: TokenType { return .dotAccess }
        
        func matches(_ segment: Segment) -> Bool {
            guard !segment.tokens.onSameLine.isEmpty else {
                return false
            }
            
            guard segment.isValidSymbol else {
                return false
            }
            
            guard segment.tokens.previous.isAny(of: ".", "(.", "[.") else {
                return false
            }
            
            guard !segment.tokens.current.isAny(of: "self", "init") else {
                return false
            }
            
            return segment.tokens.onSameLine.first != "import"
        }
    }
    
    struct KeyPathRule: SyntaxRule {
        var tokenType: TokenType { return .property }
        
        func matches(_ segment: Segment) -> Bool {
            return segment.tokens.previous.isAny(of: #"\."#, #"(\."#)
        }
    }
    
    struct PropertyRule: SyntaxRule {
        var tokenType: TokenType { return .property }
        
        func matches(_ segment: Segment) -> Bool {
            let currentToken = segment.tokens.current
            
            if currentToken.first == "$" {
                let secondIndex = currentToken.index(after: currentToken.startIndex)
                
                guard secondIndex != currentToken.endIndex else {
                    return false
                }
                
                return currentToken[secondIndex].isLetter
            }
            
            guard !segment.tokens.onSameLine.isEmpty else {
                return false
            }
            
            guard segment.isValidSymbol else {
                return false
            }
            
            guard segment.tokens.previous.isAny(of: ".", "?.", "().", ").", ">.") else {
                return false
            }
            
            guard !currentToken.isAny(of: "self", "init") else {
                return false
            }
            
            guard !segment.prefixedByDotAccess else {
                return false
            }
            
            if let next = segment.tokens.next {
                guard !next.hasPrefix("(") else {
                    return false
                }
            }
            
            return segment.tokens.onSameLine.first != "import"
        }
    }
    
    struct DeclarationRule: SyntaxRule {
        var tokenType: TokenType { return .declaration }
        
        func matches(_ segment: Segment) -> Bool {
            let keywords: Set<String> = [
                "class", "function"
            ]
            
            let currentToken = segment.tokens.current
            
            guard currentToken.replacingOccurrences(of: "_", with: "").isAlphanumeric else {
                return false
            }
            
            if let previousToken = segment.tokens.previous {
                guard !previousToken.isAny(of: keywords) else {
                    return true
                }
            }
            
            return false
        }
    }
    
    struct OtherDeclarationRule: SyntaxRule {
        var tokenType: TokenType { return .otherDeclaration }
        
        func matches(_ segment: Segment) -> Bool {
            let currentToken = segment.tokens.current
            
            guard segment.tokens.previous.isAny(of: "function", "var", "let", "const", "case", "for") else {
                return false
            }
            
            guard currentToken.replacingOccurrences(of: "_", with: "").isAlphanumeric else {
                return false
            }
            
            return true
        }
    }
    
    struct ParameterRule: SyntaxRule {
        var tokenType: TokenType { return .otherDeclaration }
        
        func matches(_ segment: Segment) -> Bool {
            guard let last = segment.tokens.all.lastIndex(where: { $0.isAny(of: "function") }) else {
                return false
            }
            
            let signature = segment.tokens.all[last...segment.tokens.all.count - 1]
            
            var level = 0
            for component in signature.reversed() {
                if component == "(" {
                    level += 1
                } else if component == ")" {
                    level -= 1
                    
                    if level == 0 {
                        return false
                    }
                }
            }
            
            guard segment.tokens.current.isAlphanumeric else {
                return false
            }
            
            if segment.tokens.previous.isAny(of: ":") {
                return false
            }
            
            guard segment.tokens.previous.isAny(of: "(", ",") else {
                return false
            }
            
            guard !segment.tokens.next.isAny(of: ")", ".", ".)") else {
                return false
            }
            
            return level == 1
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
            if token.hasPrefix("(") || token.hasPrefix("#(") || (token.hasPrefix("\"") || token.hasPrefix("`") || token.hasPrefix("'") ) {
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
//        let delimiter = "\\("
//
//        if tokens.current == delimiter || tokens.previous == delimiter {
//            return true
//        }
//
//        let components = tokens.onSameLine.split(separator: delimiter)
//
//        guard components.count > 1 else {
//            return false
//        }
//
//        let suffix = components.last!
//        var paranthesisCount = 1
//
//        for component in suffix {
//            paranthesisCount += component.numberOfOccurrences(of: "(")
//            paranthesisCount -= component.numberOfOccurrences(of: ")")
//
//            guard paranthesisCount > 0 else {
//                return false
//            }
//        }
//
//        return true
        return false
    }
    
    var isWithinParanthesis: Bool {
        let delimiter = "("
        
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
    
    var isWithinRawStringInterpolation: Bool {
//        // Quick fix for supporting single expressions within raw string
//        // interpolation, a proper fix should be developed ASAP.
//        switch tokens.current {
//        case "\\":
//            return tokens.previous != "\\" && tokens.next == "#"
//        case "#":
//            return tokens.previous == "\\" && tokens.next == "("
//        case "(":
//            return tokens.onSameLine.suffix(2) == ["\\", "#"]
//        case ")":
//            let suffix = tokens.onSameLine.suffix(4)
//            return suffix.prefix(3) == ["\\", "#", "("]
//        default:
//            let suffix = tokens.onSameLine.suffix(3)
//            return suffix == ["\\", "#", "("] && tokens.next == ")"
//        }
        return false
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
