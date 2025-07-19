// PrivacyInfoView.swift

import SwiftUI

struct PrivacyInfoView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle.weight(.bold))
                    .padding(.bottom, 5)

                Text("""
                    **Effective Date:** July 20, 2025

                    Your privacy is important to us. This Privacy Policy explains how "Open Mining Hub" ("the App," "we," "us," or "our") handles information. Our core philosophy is to collect as little data as possible to provide our services.
                    """)
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.secondaryText)
                    .padding(.bottom, 15)

                Group {
                    Text("1. No Personal Data Collection")
                        .font(.headline)
                    Text("We do not collect, store, sell, or transmit any personally identifiable information (PII). The App is designed to be a private dashboard for your devices. We do not require user accounts, and therefore we do not collect names, email addresses, passwords, or other contact information. We do not use device identifiers (like IDFA) for tracking, nor do we access your location data, contacts, or photos.")
                }

                Group {
                    Text("2. Data Stored Locally On Your Device")
                        .font(.headline)
                    Text("All configuration data you create within the App is stored exclusively on your device and is never transmitted to us or any third party. This includes your device IP addresses, network scan settings, display preferences, financial settings (like currency and electricity rates), and custom hostname color rules.")
                }

                Group {
                    Text("3. Necessary Permissions")
                        .font(.headline)
                    Text("""
                        • **Local Network Access:** The App's primary function is to discover and communicate with your mining devices on your local Wi-Fi network. We request this permission solely to scan for your devices and retrieve their statistics. All communication between the App and your devices remains on your local network.

                        • **Internet Connection:** The App connects to the internet for the sole purpose of fetching public, anonymous data about the Bitcoin network from reputable third-party APIs (CoinGecko, Blockstream, Blockchain.com). This includes the current price, block height, and network difficulty. No personal or device-specific information is ever included in these requests.
                        """)
                }

                Group {
                    Text("4. Clipboard Usage")
                        .font(.headline)
                    Text("The 'Tip Jar' feature in the App includes a button that allows you to conveniently copy a cryptocurrency address to your clipboard. The App only **writes** to the clipboard when you explicitly tap this button. It does not read, monitor, or store the contents of your clipboard at any time.")
                }

                Group {
                    Text("5. Diagnostics & Crash Reports")
                        .font(.headline)
                    Text("To help us improve the App, we may receive anonymized, aggregated crash reports and diagnostic information through Apple's App Store Connect service. This information contains no personal data and is used solely for debugging purposes to fix bugs and enhance stability.")
                }
                
                Group {
                    Text("6. Children's Privacy")
                        .font(.headline)
                    Text("This App is not intended for use by children under the age of 13. We do not knowingly collect any information from children.")
                }

                Group {
                    Text("7. Changes to This Privacy Policy")
                        .font(.headline)
                    Text("We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the 'Effective Date' at the top. You are advised to review this Privacy Policy periodically for any changes.")
                }
                
                Group {
                    Text("8. Contact Us")
                        .font(.headline)
                    Text("If you have any questions about this Privacy Policy, you can contact us via the 'Feedback' option in the App's settings.")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(themeManager.colors.backgroundGradient.ignoresSafeArea())
        .foregroundColor(themeManager.colors.primaryText)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct PrivacyInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacyInfoView()
                .environmentObject(ThemeManager())
        }
    }
}
#endif
