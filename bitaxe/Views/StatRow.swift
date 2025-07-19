//
//  StatRow.swift
//  bitaxe
//
//  Created by Brent Parks on 6/15/25.
//

// StatRow.swift

import SwiftUI

struct StatRow: View {
    let label: String
    let value: String
    var infoText: String? = nil
    var onToggle: (() -> Void)? = nil // Action for a new toggle button
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingInfo = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(themeManager.colors.primaryText)
            
            if let infoText = infoText {
                Button(action: { showingInfo.toggle() }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain) // Ensures the button is treated as an independent control
                // ACCESSIBILITY: Add a descriptive label for the info button.
                .accessibilityLabel("More information about \(label)")
                .sheet(isPresented: $showingInfo) {
                    VStack(spacing: 20) {
                        Text(label)
                            .font(.title.bold())
                        Text(infoText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .presentationDetents([.fraction(0.3)])
                }
            }
            
            Spacer()
            
            Text(value)
                .foregroundColor(themeManager.colors.secondaryText)
                .multilineTextAlignment(.trailing)
            
            // If an onToggle action is provided, show the toggle button
            if let onToggle = onToggle {
                Button(action: onToggle) {
                    Image(systemName: "arrow.left.arrow.right.circle")
                        .foregroundColor(themeManager.colors.accent)
                }
                .buttonStyle(.plain) // Ensures the button is treated as an independent control
                // ACCESSIBILITY: Add a descriptive label for the toggle button.
                .accessibilityLabel("Toggle format for \(label)")
                .padding(.leading, 4) // Add some space
            }
        }
    }
}


#if DEBUG
struct StatRow_Previews: PreviewProvider {
    static var previews: some View {
        // Example preview in a Form
        Form {
            StatRow(label: "Example Stat", value: "123.45", infoText: "This is an example explanation for the stat.")
            StatRow(label: "Toggle Stat", value: "Value", infoText: "Info for toggle.", onToggle: { print("Toggled!") })
        }
        .environmentObject(ThemeManager())
    }
}
#endif
