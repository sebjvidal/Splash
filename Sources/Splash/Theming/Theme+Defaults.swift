/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation
import SwiftUI

#if !os(Linux)

public extension Theme {
    static let defaults = ["Xcode", "VS Code"]
    
    static func `default`(forKey key: String, withFont font: Font) -> Theme? {
        let defaults: [String: Theme] = [
            "Xcode": xcodeDefault(withFont: font),
            "VS Code": vsCodeDefault(withFont: font)
        ]
        
        if let theme = defaults[key] {
            return theme
        }
        
        return nil
    }
    
    static func xcodeDefault(withFont font: Font) -> Theme {
        return Theme(
            font: font,
            plainTextColor: DynamicColour(light: Color(red: 0, green: 0, blue: 0), dark: Color(red: 1, green: 1, blue: 1)),
            tokenColors: [
                .keyword: DynamicColour(light: Color(red: 155/255, green: 35/255, blue: 147/255), dark: Color(red: 252/255, green: 95/255, blue: 163/255)),
                .string: DynamicColour(light: Color(red: 196/255, green: 26/255, blue: 22/255), dark: Color(red: 252/255, green: 106/255, blue: 93/255)),
                .type: DynamicColour(light: Color(red: 108/255, green: 54/255, blue: 169/255), dark: Color(red: 161/255, green: 103/255, blue: 230/255)),
                .otherType: DynamicColour(light: Color(red: 28/255, green: 70/255, blue: 74/255), dark: Color(red: 158/255, green: 241/255, blue: 221/255)),
                .call: DynamicColour(light: Color(red: 50/255, green: 109/255, blue: 116/255), dark: Color(red: 103/255, green: 183/255, blue: 164/255)),
                .number: DynamicColour(light: Color(red: 28/255, green: 0/255, blue: 207/255), dark: Color(red: 208/255, green: 191/255, blue: 105/255)),
                .comment: DynamicColour(light: Color(red: 93/255, green: 108/255, blue: 121/255), dark: Color(red: 108/255, green: 121/255, blue: 134/255)),
                .url: DynamicColour(light: Color(red: 14/255, green: 14/255, blue: 255/255), dark: Color(red: 84/255, green: 130/255, blue: 255/255)),
                .property: DynamicColour(light: Color(red: 50/255, green: 109/255, blue: 116/255), dark: Color(red: 103/255, green: 183/255, blue: 164/255)),
                .dotAccess: DynamicColour(light: Color(red: 50/255, green: 109/255, blue: 116/255), dark: Color(red: 103/255, green: 183/255, blue: 164/255)),
                .preprocessing: DynamicColour(light: Color(red: 100/255, green: 56/255, blue: 32/255), dark: Color(red: 253/255, green: 143/255, blue: 63/255)),
                .declaration: DynamicColour(light: Color(red: 11/255, green: 79/255, blue: 121/255), dark: Color(red: 93/255, green: 216/255, blue: 255/255)),
                .otherDeclaration: DynamicColour(light: Color(red: 15/255, green: 104/255, blue: 160/255), dark: Color(red: 65/255, green: 161/255, blue: 192/255))
            ],
            backgroundColor: DynamicColour(light: Color(red: 1, green: 1, blue: 1), dark: Color(red: 0, green: 0, blue: 0))
        )
    }
    
    static func vsCodeDefault(withFont font: Font) -> Theme {
        return Theme(
            font: font,
            plainTextColor: DynamicColour(light: Color(red: 0, green: 0, blue: 0), dark: Color(red: 1, green: 1, blue: 1)),
            tokenColors: [
                .keyword: DynamicColour(light: Color(red: 86/255, green: 156/255, blue: 214/255), dark: Color(red: 86/255, green: 156/255, blue: 214/255)),
                .string: DynamicColour(light: Color(red: 206/255, green: 145/255, blue: 120/255), dark: Color(red: 206/255, green: 145/255, blue: 120/255)),
                .type: DynamicColour(light: Color(red: 78/255, green: 201/255, blue: 176/255), dark: Color(red: 78/255, green: 201/255, blue: 176/255)),
                .otherType: DynamicColour(light: Color(red: 195/255, green: 106/255, blue: 183/255), dark: Color(red: 195/255, green: 106/255, blue: 183/255)),
                .call: DynamicColour(light: Color(red: 120/255, green: 214/255, blue: 255/255), dark: Color(red: 120/255, green: 214/255, blue: 255/255)),
                .number: DynamicColour(light: Color(red: 160/255, green: 198/255, blue: 147/255), dark: Color(red: 160/255, green: 198/255, blue: 147/255)),
                .comment: DynamicColour(light: Color(red: 75/255, green: 140/255, blue: 60/255), dark: Color(red: 75/255, green: 140/255, blue: 60/255)),
                .url: DynamicColour(light: Color(red: 117/255, green: 193/255, blue: 89/255), dark: Color(red: 117/255, green: 193/255, blue: 89/255)),
                .property: DynamicColour(light: Color(red: 120/255, green: 214/255, blue: 255/255), dark: Color(red: 120/255, green: 214/255, blue: 255/255)),
                .dotAccess: DynamicColour(light: Color(red: 120/255, green: 214/255, blue: 255/255), dark: Color(red: 120/255, green: 214/255, blue: 255/255)),
                .preprocessing: DynamicColour(light: Color(red: 100/255, green: 56/255, blue: 32/255), dark: Color(red: 253/255, green: 143/255, blue: 63/255)),
                .declaration: DynamicColour(light: Color(red: 0/255, green: 189/255, blue: 154/255), dark: Color(red: 0/255, green: 189/255, blue: 154/255)),
                .otherDeclaration: DynamicColour(light: Color(red: 220/255, green: 220/255, blue: 178/255), dark: Color(red: 220/255, green: 220/255, blue: 178/255))
            ],
            backgroundColor: DynamicColour(light: Color(red: 1, green: 1, blue: 1), dark: Color(red: 0, green: 0, blue: 0))
        )
    }
    
    static func from(_ dictionary: [String: Any], named name: String, withFont font: Font) -> Theme {
        let keys: [TokenType: String] = [
            .keyword: "xcode.syntax.keyword",
            .string: "xcode.syntax.string",
            .type: "xcode.syntax.identifier.variable.system",
            .otherType: "xcode.syntax.identifier.type",
            .call: "xcode.syntax.identifier.function",
            .number: "xcode.syntax.number",
            .comment: "xcode.syntax.comment",
            .url: "xcode.syntax.url",
            .property: "xcode.syntax.identifier.function",
            .dotAccess: "xcode.syntax.identifier.function",
            .preprocessing: "xcode.syntax.preprocessor",
            .declaration: "xcode.syntax.declaration.type",
            .otherDeclaration: "xcode.syntax.declaration.other"
        ]
        
        if let themeJson = dictionary[name] as? [String: Any] {
            var tokens: [TokenType: DynamicColour] = [:]
            
            for key in keys {
                if let colour = themeJson[key.value] as? [String: Any] {
                    let light = colour["light"] as! NSArray
                    let dark = colour["dark"] as! NSArray
                    let dynamic = DynamicColour(
                        light: Color(red: light[0] as! CGFloat, green: light[1] as! CGFloat, blue: light[2] as! CGFloat),
                        dark: Color(red: dark[0] as! CGFloat, green: dark[1] as! CGFloat, blue: dark[2] as! CGFloat)
                    )
                    
                    tokens[key.key] = dynamic
                }
            }
            
            if let plainText = themeJson["xcode.syntax.plain"] as? [String: Any] {
                let light = plainText["light"] as! NSArray
                let dark = plainText["dark"] as! NSArray
                let dynamicPlain = DynamicColour(
                    light: Color(red: light[0] as! CGFloat, green: light[1] as! CGFloat, blue: light[2] as! CGFloat),
                    dark: Color(red: dark[0] as! CGFloat, green: dark[1] as! CGFloat, blue: dark[2] as! CGFloat)
                )
            
                return Theme(
                    font: font,
                    plainTextColor: dynamicPlain,
                    tokenColors: tokens,
                    backgroundColor: DynamicColour(light: Color(red: 1, green: 1, blue: 1), dark: Color(red: 0, green: 0, blue: 0))
                )
            }
        }
        
        return .xcodeDefault(withFont: font)
    }
}

#endif
