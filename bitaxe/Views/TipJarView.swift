import SwiftUI
import Combine // Required for TimelineView

// A simple struct to hold the properties of a single confetti particle.
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    // Physics properties
    let xVelocity: CGFloat
    let yVelocity: CGFloat
    let rotationSpeed: Double
    let startTime: Double
}

struct TipJarView: View {
    @EnvironmentObject var themeManager: ThemeManager

    // --- Original State & Properties ---
    private let bitcoinAddress = "bc1q4lnnmcq7sqc2nc7dmytlpexm3x027gtrmuuws8cxpzcz25ekxcrq8qt6r8"
    private let lightningAddress = "salt@strike.com"
    private let lightningUriForQR = "lightning:SALT@STRIKE.COM"
    private let bitcoinUriForQR = "bitcoin:bc1q4lnnmcq7sqc2nc7dmytlpexm3x027gtrmuuws8cxpzcz25ekxcrq8qt6r8"


    @State private var isBitcoinSectionExpanded: Bool = false
    @State private var isLightningSectionExpanded: Bool = false

    @State private var feedbackMessage: String?
    @State private var showFeedbackToast: Bool = false
    @State private var feedbackIDForToast: UUID = UUID()

    private let bitcoinOrangeToastColor = Color(hex: "#F7931A") ?? .orange
    
    // --- New State for Confetti ---
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var isConfettiActive: Bool = false

    // --- Methods ---
    private func copyToClipboard(text: String, addressType: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
        
        presentFeedbackToast(message: "\(addressType) address copied!")
    }

    private func presentFeedbackToast(message: String) {
        feedbackMessage = message
        feedbackIDForToast = UUID()
        withAnimation(.spring()) {
            showFeedbackToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFeedbackToast = false
            }
        }
    }
    
    private func triggerConfetti() {
        guard !isConfettiActive else { return }
        isConfettiActive = true
        
        let screenWidth = UIScreen.main.bounds.width
        let creationTime = Date().timeIntervalSinceReferenceDate
        
        // --- THIS IS THE CHANGE (4x more coins) ---
        confettiParticles = (0..<300).map { _ in
        // --- END CHANGE ---
            ConfettiParticle(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: 50...150) * -1,
                size: CGFloat.random(in: 20...35),
                opacity: Double.random(in: 0.7...1.0),
                xVelocity: CGFloat.random(in: -20...20),
                yVelocity: CGFloat.random(in: 100...200),
                rotationSpeed: Double.random(in: -180...180),
                startTime: creationTime
            )
        }
        
        // Reset after the animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            isConfettiActive = false
            confettiParticles = []
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            themeManager.colors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    Text("If you find this app useful, please consider sending a tip for its development.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .foregroundColor(themeManager.colors.primaryText)

                    DisclosureGroup(isExpanded: $isBitcoinSectionExpanded) {
                        VStack(spacing: 12) {
                            Text("Tap address to copy or scan QR:")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.secondaryText)
                                .padding(.top, 5)
                            if let qrImage = QRCodeHelper.generateQRCode(from: bitcoinUriForQR) {
                                qrImage.interpolation(.none).resizable().scaledToFit().frame(width: 180, height: 180)
                                    .contextMenu { Button { copyToClipboard(text: bitcoinAddress, addressType: "Bitcoin") } label: { Label("Copy Bitcoin Address", systemImage: "doc.on.doc") } }
                            } else { Text("Error generating Bitcoin QR code").foregroundColor(.red) }
                            Text(bitcoinAddress).font(.system(.callout, design: .monospaced).weight(.medium)).padding(10).background(themeManager.colors.tertiaryBackground).cornerRadius(8)
                                .onTapGesture { copyToClipboard(text: bitcoinAddress, addressType: "Bitcoin") }
                        }
                        .padding(.vertical, 10)
                    } label: {
                        Image(systemName: "link")
                        Text("Bitcoin (On-chain)").font(.title2.bold()).foregroundColor(themeManager.colors.primaryText)
                    }
                    .padding()
                    .background(themeManager.colors.cardBackground)
                    .cornerRadius(12)

                    DisclosureGroup(isExpanded: $isLightningSectionExpanded) {
                        VStack(spacing: 12) {
                            Text("Tap address to copy or scan QR:").font(.caption).foregroundColor(themeManager.colors.secondaryText).padding(.top, 5)
                            if let qrImage = QRCodeHelper.generateQRCode(from: lightningUriForQR) {
                                qrImage.interpolation(.none).resizable().scaledToFit().frame(width: 180, height: 180)
                                    .contextMenu { Button { copyToClipboard(text: lightningAddress, addressType: "Lightning") } label: { Label("Copy Lightning Address", systemImage: "doc.on.doc") } }
                            } else { Text("Error generating Lightning QR code").foregroundColor(.red) }
                            Text(lightningAddress).font(.system(.callout, design: .monospaced).weight(.medium)).padding(10).background(themeManager.colors.tertiaryBackground).cornerRadius(8)
                                .onTapGesture { copyToClipboard(text: lightningAddress, addressType: "Lightning") }
                        }
                        .padding(.vertical, 10)
                    } label: {
                        Image(systemName: "bolt.fill")
                        Text("Bitcoin (Lightning Network)").font(.title2.bold()).foregroundColor(themeManager.colors.primaryText)
                    }
                    .padding()
                    .background(themeManager.colors.cardBackground)
                    .cornerRadius(12)
                    
                    Image("TipJarGraphic")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(40)
                        .frame(maxWidth: .infinity, maxHeight: 180)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .onTapGesture {
                            // --- HAPTICS GO CRAZY HERE ---
                            let hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
                            // Create a quick burst of 5 haptic taps over ~0.3 seconds
                            for i in 0..<5 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                                    hapticGenerator.impactOccurred(intensity: 0.8)
                                }
                            }
                            // --- END HAPTICS ---
                            
                            triggerConfetti()
                        }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Tip Jar")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            
            if showFeedbackToast, let message = feedbackMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(bitcoinOrangeToastColor.opacity(0.90))
                    .foregroundColor(Color.white)
                    .clipShape(Capsule())
                    .shadow(radius: 5)
                    .id(feedbackIDForToast)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 40)
                    .zIndex(1)
            }
            
            if isConfettiActive {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let currentTime = timeline.date.timeIntervalSinceReferenceDate
                        
                        for particle in confettiParticles {
                            let timeAlive = currentTime - particle.startTime
                            let gravity: CGFloat = 400

                            let newY = particle.y + (particle.yVelocity * timeAlive) + (0.5 * gravity * pow(timeAlive, 2))
                            let newX = particle.x + (particle.xVelocity * timeAlive)
                            
                            let rotationAngle = Angle(degrees: particle.rotationSpeed * timeAlive)
                            
                            var innerContext = context
                            innerContext.translateBy(x: newX, y: newY)
                            innerContext.rotate(by: rotationAngle)
                            
                            if let resolvedImage = context.resolveSymbol(id: particle.id) {
                                innerContext.draw(resolvedImage, at: .zero)
                            }
                        }
                    } symbols: {
                        ForEach(confettiParticles) { particle in
                             Image("bitcoin-icon")
                                .resizable()
                                .frame(width: particle.size, height: particle.size)
                                .tag(particle.id)
                        }
                    }
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .zIndex(2)
            }
        }
    }
}


#if DEBUG
struct TipJarView_Previews: PreviewProvider {
    class PreviewThemeManager: ObservableObject {
        @Published var colors = (
            backgroundGradient: LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.4)]), startPoint: .top, endPoint: .bottom),
            primaryText: Color.primary,
            secondaryText: Color.secondary,
            cardBackground: Color(.systemGray5),
            tertiaryBackground: Color(.systemGray6)
        )
    }

    static var previews: some View {
        NavigationView {
            TipJarView()
                .environmentObject(PreviewThemeManager())
        }
    }
}
#endif
