// WelcomeView.swift

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // Define two separate actions for the two buttons
    let onGetStarted: () -> Void
    let onGoToSettings: () -> Void

    // State to control the presentation of the disclaimer sheet
    @State private var showingDisclaimerSheet = false
    @State private var showingPrivacySheet = false

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            
            Image("AppLogo")
                .resizable()
                .frame(width: 100, height: 100)
                .cornerRadius(22)
                .shadow(radius: 5)

            Text("Welcome to\nOpen Mining Hub")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 25) {
                FeatureRow(
                    icon: "hammer.fill",
                    title: "Monitor Your Miners",
                    description: "Keep track of hashrate, temperature, power usage, and profitability for all your devices in one place."
                )
                
                FeatureRow(icon: "wifi", title: "Local Network Scanning") {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("The app finds your devices on your local Wi-Fi.")
                        Button(action: onGoToSettings) {
                            Text("Go to Settings to add your devices to begin.")
                                .multilineTextAlignment(.leading)
                                .bold()
                        }
                    }
                }
                
                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Private and Secure",
                    description: "Your data and settings never leave your device. No user accounts, no tracking, and no data collection. Ever."
                )
                
                FeatureRow(
                    icon: "paintpalette.fill",
                    title: "Make It Yours",
                    description: "Customize your dashboard with multiple color themes, light/dark modes, and display options in Settings."
                )
                
                FeatureRow(
                    icon: "chevron.left.slash.chevron.right",
                    title: "Open Source",
                    description: "This will always be open source and free"
                )
            }
            .padding()
            
            Spacer()

            // --- NEW: Disclaimer Text and Link ---
            VStack(spacing: 4) {
                Text("By pressing the button below (Lets Get Mining), you agree to the")
                    .font(.caption)
                    .foregroundColor(themeManager.colors.secondaryText)
                
                HStack(spacing: 15) {
                    Button("Disclaimer & Terms of Use") {
                        showingDisclaimerSheet = true
                    }
                    .font(.caption.weight(.semibold))
                    // Ensure the button tint matches the theme for visibility
                    .tint(themeManager.colors.accent)

                    Button("Privacy Policy") {
                        showingPrivacySheet = true
                    }
                    .font(.caption.weight(.semibold))
                    .tint(themeManager.colors.accent)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            Button(action: onGetStarted) {
                Text("Lets Get Mining")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.colors.accent)
                    .foregroundColor(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(themeManager.colors.backgroundGradient.ignoresSafeArea())
        .foregroundColor(themeManager.colors.primaryText)
        // --- NEW: Sheet Modifier to present the Disclaimer ---
        .sheet(isPresented: $showingDisclaimerSheet) {
            // Wrap DisclaimerView in a NavigationView to give it a title and a Done button
            NavigationView {
                DisclaimerView()
                    .navigationBarItems(trailing: Button("Done") {
                        showingDisclaimerSheet = false
                    }.tint(themeManager.colors.accent))
            }
            .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingPrivacySheet) {
            // Wrap PrivacyInfoView in a NavigationView to give it a title and a Done button
            NavigationView {
                PrivacyInfoView()
                    .navigationBarItems(trailing: Button("Done") {
                        showingPrivacySheet = false
                    }.tint(themeManager.colors.accent))
            }
            .environmentObject(themeManager)
        }
    }
}

// A helper view to keep the layout clean, now with a custom content closure
struct FeatureRow<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }

    init(icon: String, title: String, description: String) where Content == Text {
        self.init(icon: icon, title: title) {
            Text(description)
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(themeManager.colors.accent)
                .frame(width: 50, alignment: .top)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.primaryText)
                
                content
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.secondaryText)
            }
        }
    }
}

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(onGetStarted: {}, onGoToSettings: {})
            .environmentObject(ThemeManager())
    }
}
#endif
