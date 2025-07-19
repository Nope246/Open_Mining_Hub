// ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    @EnvironmentObject var themeManager: ThemeManager
    
    @AppStorage("isBitcoinFallAnimationEnabled_v1") private var isBitcoinFallAnimationEnabled: Bool = true
    @AppStorage("customTheme_isBitcoinFallAnimationEnabled") private var isCustomThemeAnimationEnabled: Bool = false

    @AppStorage("hasShownWelcomeScreen_v1") private var hasShownWelcomeScreen: Bool = false
    @State private var showingWelcomeScreen = false
    
    @State private var selectedTab: Int = 0
    @State private var navigateToNetworkSettings = false
    
    // --- NEW: State to control the 'How to Use' pop-up ---
    @State private var showingHowToUse = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView(viewModel: viewModel)
                    .tabItem {
                        Label("Dashboard", systemImage: "hammer.fill")
                    }
                    .tag(0)

                SettingsView(navigateToNetworkSettings: $navigateToNetworkSettings)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(1)
            }
            .onAppear {
                UITabBar.appearance().backgroundColor = .clear
                UITabBar.appearance().unselectedItemTintColor = .gray
            }
            .tint(themeManager.colors.accent)
            
            if shouldShowBitcoinFallAnimation() {
                BitcoinFallView()
                    .allowsHitTesting(false)
            }
        }
        .background(themeManager.colors.backgroundGradient.ignoresSafeArea())
        .environmentObject(viewModel)
        .onAppear {
            if !hasShownWelcomeScreen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingWelcomeScreen = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingWelcomeScreen) {
            WelcomeView(
                onGetStarted: {
                    hasShownWelcomeScreen = true
                    showingWelcomeScreen = false
                    // --- NEW: Show the pop-up after the welcome screen is dismissed ---
                    showingHowToUse = true
                },
                onGoToSettings: {
                    hasShownWelcomeScreen = true
                    selectedTab = 1
                    navigateToNetworkSettings = true
                    showingWelcomeScreen = false
                }
            )
            .environmentObject(themeManager)
        }
    
    }
    
    private func shouldShowBitcoinFallAnimation() -> Bool {
        let isBitcoinTheme = themeManager.selectedTheme == .bitcoin && isBitcoinFallAnimationEnabled
        let isCustomTheme = themeManager.selectedTheme == .custom && isCustomThemeAnimationEnabled
        return isBitcoinTheme || isCustomTheme
    }
}
