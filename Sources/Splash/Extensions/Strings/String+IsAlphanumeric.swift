//
//  File.swift
//  
//
//  Created by Seb Vidal on 11/02/2022.
//

import Foundation

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9-_]", options: .regularExpression) == nil
    }
    
    var isAlphanumericDash: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9-[-]]", options: .regularExpression) == nil
    }
}
