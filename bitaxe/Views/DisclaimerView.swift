// DisclaimerView.swift

import SwiftUI

struct DisclaimerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms and Conditions")
                    .font(.title.weight(.bold))
                    .padding(.bottom, 5)
                
                Text("""
                    **Last Updated:** July 20, 2025
                    Please read these Terms and Conditions ("Terms") carefully before using the Open Mining Hub application (the "App"). Your access to and use of the App is conditioned on your acceptance of and compliance with these Terms.
                    """)
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.secondaryText)
                    .padding(.bottom, 15)

                Group {
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    Text("By downloading, accessing, or using the App, you agree to be bound by these Terms. If you disagree with any part of the terms, then you may not access the App.")
                }

                Group {
                    Text("2. Disclaimer of Warranties")
                        .font(.headline)
                    Text("The App is provided to you \"AS IS\" and \"AS AVAILABLE\" and with all faults and defects without warranty of any kind. To the maximum extent permitted under applicable law, the developer expressly disclaims all warranties, whether express, implied, statutory or otherwise, with respect to the App, including all implied warranties of merchantability, fitness for a particular purpose, title, and non-infringement.")
                }

                Group {
                    Text("3. No Financial Advice")
                        .font(.headline)
                    Text("The financial calculations, hashrate data, mining projections, and other information displayed in this App are **estimates** based on data from third-party APIs and user-provided values. This information is for informational purposes only and does **not** constitute financial, investment, or professional advice. The developer makes no guarantee as to the accuracy, completeness, or timeliness of this information. You should not make financial decisions based solely on the data presented in this App.")
                }
                
                Group {
                    Text("4. Risk of Use and Hardware Interaction")
                        .font(.headline)
                    Text("This App interacts with your personal hardware (mining devices) over your local network. You acknowledge and agree that you are **solely responsible** for any and all risks associated with using this App, including but not limited to, damage to your hardware, loss of data, reduced hardware lifespan, or unexpected changes to your device configurations. The developer shall not be liable for any damage or harm caused by the use of features such as Over-the-Air (OTA) updates, device restarts, or configuration changes made through the App.")
                }
                
                Group {
                    Text("5. User Conduct")
                        .font(.headline)
                    Text("You agree not to use the App in any way that is unlawful, or harms the developer or any third party. You may not attempt to reverse engineer, decompile, or disassemble the App, except and only to the extent that such activity is expressly permitted by applicable law.")
                }

                Group {
                    Text("6. Limitation of Liability")
                        .font(.headline)
                    Text("To the fullest extent permitted by applicable law, in no event shall the developer be liable for any special, incidental, indirect, or consequential damages whatsoever (including, but not limited to, damages for loss of profits, loss of data, for business interruption, for personal injury, or loss of privacy) arising out of or in any way related to the use of or inability to use the App, even if the developer has been advised of the possibility of such damages.")
                }
                
                Group {
                    Text("7. Termination")
                        .font(.headline)
                    Text("We may terminate or suspend your access to our App immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.")
                }
                
                Group {
                    Text("8. Governing Law")
                        .font(.headline)
                    Text("These Terms shall be governed and construed in accordance with the laws of the jurisdiction in which the developer is based, without regard to its conflict of law provisions.")
                }

                Text("By using this App, you are agreeing to these Terms and Conditions.")
                    .font(.headline)
                    .padding(.top, 15)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(themeManager.colors.backgroundGradient.ignoresSafeArea())
        .foregroundColor(themeManager.colors.primaryText)
        .navigationTitle("Terms & Conditions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DisclaimerView()
                .environmentObject(ThemeManager())
        }
    }
}
#endif
