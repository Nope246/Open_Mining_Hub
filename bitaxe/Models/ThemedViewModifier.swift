// ThemedViewModifier.swift

import SwiftUI

struct Themed: ViewModifier {
    @StateObject private var themeManager = ThemeManager()

    func body(content: Content) -> some View {
        content
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            .accentColor(themeManager.colors.accent)
            // The following line should be removed.
            // .background(themeManager.colors.backgroundGradient.ignoresSafeArea())
    }
}

extension View {
    func themed() -> some View {
        self.modifier(Themed())
    }
}
//END of ThemedViewModifier.swift
