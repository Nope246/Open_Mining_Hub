// CustomTheme.swift
//  bitaxe
//
//  Created by Brent Parks on 6/2/25.

import SwiftUI

struct CustomTheme {
    // We store the hex strings in AppStorage
    @AppStorage("customTheme_accent") private var accent: String = "#FFA500" // Default: Orange
    @AppStorage("customTheme_background") private var background: String = "#121212" // Default: Dark Gray
    @AppStorage("customTheme_cardBackground") private var cardBackground: String = "#1E1E1E" // Default: Lighter Gray
    @AppStorage("customTheme_primaryText") private var primaryText: String = "#FFFFFF" // Default: White
    @AppStorage("customTheme_secondaryText") private var secondaryText: String = "#8E8E93" // Default: Gray
    @AppStorage("customTheme_isDarkMode") private var isDarkMode: Bool = true // Default: Custom theme is dark

    // --- NEW: Store animation preference for custom theme ---
    @AppStorage("customTheme_isBitcoinFallAnimationEnabled") private var isBitcoinFallAnimationEnabled: Bool = false

    /// Provides the `ThemeColors` object for the custom theme by reading from AppStorage
    func getThemeColors() -> ThemeColors {
        let accentColor = Color(hex: accent) ?? .orange
        let backgroundColor = Color(hex: background) ?? .black
        let cardBackgroundColor = Color(hex: cardBackground) ?? Color(.secondarySystemBackground)
        let primaryTextColor = Color(hex: primaryText) ?? .primary
        let secondaryTextColor = Color(hex: secondaryText) ?? .secondary
        
        return ThemeColors(
            accent: accentColor,
            background: backgroundColor,
            cardBackground: cardBackgroundColor,
            tertiaryBackground: cardBackgroundColor.opacity(0.8),
            groupedBackground: cardBackgroundColor.opacity(0.8),
            primaryText: primaryTextColor,
            secondaryText: secondaryTextColor,
            backgroundGradient: LinearGradient(gradient: Gradient(colors: [backgroundColor.opacity(0.8), backgroundColor]), startPoint: .top, endPoint: .bottom),
            positiveHighlight: accentColor.opacity(0.2),
            neutralHighlight: cardBackgroundColor
        )
    }
    
    /// Returns the raw data needed for the editor view
    func getEditorData() -> (colors: [Color], hexStrings: [String], isDark: Bool, isAnimationEnabled: Bool) {
        let theme = getThemeColors()
        let colors = [theme.accent, theme.background, theme.cardBackground, theme.primaryText, theme.secondaryText]
        let hexStrings = [accent, background, cardBackground, primaryText, secondaryText]
        return (colors, hexStrings, isDarkMode, isBitcoinFallAnimationEnabled)
    }

    /// Saves the new custom theme data back to AppStorage
    func save(hexStrings: [String], isDark: Bool, isAnimationEnabled: Bool) {
        guard hexStrings.count == 5 else { return }
        
        self.accent = hexStrings[0]
        self.background = hexStrings[1]
        self.cardBackground = hexStrings[2]
        self.primaryText = hexStrings[3]
        self.secondaryText = hexStrings[4]
        self.isDarkMode = isDark
        self.isBitcoinFallAnimationEnabled = isAnimationEnabled
    }
    
    /// Returns the color scheme for the custom theme
    var colorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }
}
