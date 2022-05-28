/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

#if !os(Linux)

import Foundation
import UIKit.UITraitCollection

/// Output format to use to generate an NSAttributedString from the
/// highlighted code. A `Theme` is used to determine what fonts and
/// colors to use for the various tokens.
public struct AttributedStringOutputFormat: OutputFormat {
    public var theme: Theme
    public var appearance: UIUserInterfaceStyle

    public init(theme: Theme, appearance: UIUserInterfaceStyle) {
        self.theme = theme
        self.appearance = appearance
    }

    public func makeBuilder() -> Builder {
        return Builder(theme: theme, appearance: appearance)
    }
}

public extension AttributedStringOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: Theme
        private let appearance: UIUserInterfaceStyle
        private lazy var font = theme.font.load()
        private var string = NSMutableAttributedString()

        fileprivate init(theme: Theme, appearance: UIUserInterfaceStyle) {
            self.theme = theme
            self.appearance = appearance
        }

        public mutating func addToken(_ token: String, ofType type: TokenType) {
            let dynamic = theme.tokenColors[type] ?? DynamicColour()
            let color: Color
            
            switch appearance {
            case .dark:
                color = dynamic.dark
            default:
                color = dynamic.light
            }
            
            string.append(token, font: font, color: color)
        }

        public mutating func addPlainText(_ text: String) {
            let dynamic = theme.plainTextColor
            let color: Color
            
            switch appearance {
            case .dark:
                color = dynamic.dark
            default:
                color = dynamic.light
            }
            
            string.append(text, font: font, color: color)
        }

        public mutating func addWhitespace(_ whitespace: String) {
            let color = Color(red: 1, green: 1, blue: 1)
            string.append(whitespace, font: font, color: color)
        }

        public func build() -> NSAttributedString {
            return NSAttributedString(attributedString: string)
        }
    }
}

private extension NSMutableAttributedString {
    func append(_ string: String, font: Font.Loaded, color: Color) {
        let attributedString = NSAttributedString(string: string, attributes: [
            .foregroundColor: color,
            .font: font
        ])

        append(attributedString)
    }
}
#endif
