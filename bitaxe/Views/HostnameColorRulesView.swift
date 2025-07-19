import SwiftUI

struct HostnameColorRulesView: View {
    // --- MODIFIED: Use the manager from the environment ---
    @EnvironmentObject var manager: HostnameColorManager
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Form {
            Section(header: Text("Color Rules"), footer: Text("Rules are applied in order. The first rule that matches a hostname will be used.")) {
                // The ForEach now uses the environment object manager
                ForEach($manager.rules) { $rule in
                    HStack(spacing: 15) {
                        Picker("Match Type", selection: $rule.matchType) {
                            ForEach(HostnameColorRule.MatchType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()

                        TextField("Text (e.g., 's19', 'pro')", text: $rule.matchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        ColorPicker("", selection: Binding(
                            get: { Color(hex: rule.hexColor) ?? .white },
                            set: { rule.hexColor = $0.toHex() ?? "#FFFFFF" }
                        ), supportsOpacity: false)
                    }
                }
                .onDelete { indices in
                    manager.rules.remove(atOffsets: indices)
                }
                .onMove { source, destination in
                    manager.rules.move(fromOffsets: source, toOffset: destination)
                }
            }

            Section {
                Button("Add New Rule") {
                    manager.rules.append(HostnameColorRule())
                }
            }
        }
        .navigationTitle("Hostname Color Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .background(themeManager.colors.backgroundGradient.ignoresSafeArea())
        .scrollContentBackground(.hidden)
    }
}

struct HostnameColorRulesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // --- MODIFIED: Inject the managers for the preview ---
            HostnameColorRulesView()
                .environmentObject(ThemeManager())
                .environmentObject(HostnameColorManager())
        }
    }
}
