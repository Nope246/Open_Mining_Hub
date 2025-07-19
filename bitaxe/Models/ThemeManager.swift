// ThemeManager.swift

import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: AppTheme = .default
    private let customTheme = CustomTheme()

    var colors: ThemeColors {
        switch selectedTheme {
        case .custom:
            // If the selected theme is custom, load its colors
            return customTheme.getThemeColors()
        case .default:
            // For the default system theme, switch between light and dark modes
            return UITraitCollection.current.userInterfaceStyle == .dark ? AppTheme.themes[.dark]! : AppTheme.themes[.light]!
        default:
            // For all other predefined themes
            return AppTheme.themes[selectedTheme] ?? AppTheme.themes[.light]!
        }
    }
}
