// CustomThemeEditorView.swift

import SwiftUI
import Combine

struct CustomThemeEditorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var hexStrings: [String]
    @State private var isDarkMode: Bool
    
    // --- NEW: State for the animation toggle ---
    @State private var isAnimationEnabled: Bool

    @State private var showFeedbackToast: Bool = false
    
    private let labels = ["Accent", "Background", "Card Background", "Primary Text", "Secondary Text"]
    private let customTheme = CustomTheme()
    private let bitcoinOrangeToastColor = Color(hex: "#F7931A") ?? .orange

    init() {
        let data = customTheme.getEditorData()
        _hexStrings = State(initialValue: data.hexStrings)
        _isDarkMode = State(initialValue: data.isDark)
        
        // --- NEW: Initialize the animation state ---
        _isAnimationEnabled = State(initialValue: data.isAnimationEnabled)
    }
    
    private func presentFeedbackToast() {
        withAnimation(.spring()) {
            showFeedbackToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFeedbackToast = false
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Form {
                Section(header: Text("Color Palette")) {
                    ForEach(0..<labels.count, id: \.self) { index in
                        VStack(alignment: .leading) {
                            // --- MODIFIED: Create a custom binding for the ColorPicker ---
                            let colorBinding = Binding<Color>(
                                get: {
                                    return Color(hex: hexStrings[index]) ?? .white
                                },
                                set: { newColor in
                                    hexStrings[index] = newColor.toHex() ?? "#FFFFFF"
                                }
                            )
                            
                            ColorPicker(labels[index], selection: colorBinding, supportsOpacity: false)
                            
                            HStack {
                                Text("#")
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundColor(.secondary)
                                TextField("Hex Code", text: $hexStrings[index].binding(for: "#"))
                                    .font(.system(.footnote, design: .monospaced))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode Theme", isOn: $isDarkMode)
                    
                    // --- NEW: Toggle for the animation ---
                    Toggle("Enable Bitcoin Fall Animation", isOn: $isAnimationEnabled)
                }
                
                Section(header: Text("Advanced")) {
                    NavigationLink("Customize Hostname Colors", destination: HostnameColorRulesView())
                }
                
                Section {
                    Button("Save Theme") {
                        // 1. Save all custom theme settings
                        customTheme.save(
                            hexStrings: hexStrings,
                            isDark: isDarkMode,
                            isAnimationEnabled: isAnimationEnabled // Pass the new value
                        )
                        
                        // 2. Tell the ThemeManager to publish its changes so the UI updates
                        themeManager.objectWillChange.send()
                        
                        // 3. Show the confirmation toast
                        presentFeedbackToast()
                    }
                    .foregroundColor(themeManager.colors.accent)
                }
            }
            .navigationTitle("Custom Theme")
            .navigationBarTitleDisplayMode(.inline)
            
            // --- Toast Message Area ---
            if showFeedbackToast {
                Text("Custom Theme Saved!")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(bitcoinOrangeToastColor.opacity(0.90))
                    .foregroundColor(Color.white)
                    .clipShape(Capsule())
                    .shadow(radius: 5)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 40)
                    .zIndex(1)
            }
        }
    }
}

// Helper to bind TextField to a string while ignoring a prefix
extension Binding where Value == String {
    func binding(for prefix: String) -> Binding<String> {
        Binding<String>(
            get: {
                self.wrappedValue.hasPrefix(prefix) ? String(self.wrappedValue.dropFirst(prefix.count)) : self.wrappedValue
            },
            set: {
                self.wrappedValue = prefix + $0.filter { "0123456789ABCDEFabcdef".contains($0) }.uppercased()
            }
        )
    }
}


// Preview Provider
struct CustomThemeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CustomThemeEditorView()
                .environmentObject(ThemeManager())
                .environmentObject(HostnameColorManager())
        }
    }
}
