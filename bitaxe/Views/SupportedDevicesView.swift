import SwiftUI

struct SupportedDevicesView: View {
    @EnvironmentObject var themeManager: ThemeManager

    // This list can be updated as you add and test more models.
    private let supportedDevices: [SupportedDevice] = [
        .init(modelName: "Bitaxe (All Models)", status: .fullySupported, notes: "All standard Bitaxe models are fully supported."),
        .init(modelName: "NerdQaxe+", status: .inDevelopment, notes: "Support is currently in development. Some features may be unstable or unavailable."),
        .init(modelName: "NerdQaxe++", status: .inDevelopment, notes: "Support is currently in development. Some features may be unstable or unavailable."),
    ]

    var body: some View {
        Form {
            Section(header: Text("Device Support Status")) {
                ForEach(supportedDevices) { device in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(device.modelName)
                            .font(.headline)
                        
                        HStack {
                            Text(device.status.rawValue)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(device.status.color)
                            
                            Spacer()
                            
                            if let notes = device.notes {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listRowBackground(themeManager.colors.cardBackground)
        }
        .navigationTitle("Supported Devices")
        .background(themeManager.colors.backgroundGradient.ignoresSafeArea())
        .scrollContentBackground(.hidden)
    }
}

#if DEBUG
struct SupportedDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupportedDevicesView()
                .environmentObject(ThemeManager())
        }
    }
}
#endif
