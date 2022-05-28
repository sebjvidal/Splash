//
//  DynamicColour.swift
//  
//
//  Created by Seb Vidal on 17/02/2022.
//

import Foundation

public struct DynamicColour {
    public var light: Color
    public var dark: Color
    
    public init(light: Color = Color(red: 0, green: 0, blue: 0), dark: Color = Color(red: 1, green: 1, blue: 1)) {
        self.light = light
        self.dark = dark
    }
}

public extension DynamicColour {
    static func from(_ dictionary: [String: Any], withKey key: String) -> DynamicColour {
        return DynamicColour()
    }
}
