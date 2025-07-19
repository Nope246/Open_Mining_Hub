// BitcoinFallView.swift

import SwiftUI

private struct Particle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var size: Double
    var opacity: Double
    var speed: Double
    var initialDelay: Double
    var rotation: Angle
}

struct BitcoinFallView: View {
    @State private var particles: [Particle]
    
    // Configurable properties for the particle system
    private let count: Int
    private let sizeRange: ClosedRange<Double>
    private let speedRange: ClosedRange<Double>

    init(count: Int = 50, sizeRange: ClosedRange<Double> = 10...40, speedRange: ClosedRange<Double> = 50...150) {
        self.count = count
        self.sizeRange = sizeRange
        self.speedRange = speedRange
        
        // Initialize the state with random particles
        _particles = State(initialValue: (0..<count).map { _ in
            Particle.create(in: UIScreen.main.bounds.size, sizeRange: sizeRange, speedRange: speedRange, withDelay: true)
        })
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016, paused: false)) { context in
            GeometryReader { proxy in
                ZStack {
                    ForEach(particles) { particle in
                        Image("bitcoin-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: particle.size, height: particle.size)
                            .opacity(particle.opacity)
                            .rotationEffect(particle.rotation)
                            .position(x: particle.x, y: particle.y)
                    }
                }
                .onChange(of: context.date) {
                    for i in 0..<particles.count {
                        // Wait for any initial delay to pass
                        guard context.date.timeIntervalSinceReferenceDate > particles[i].initialDelay else { continue }
                        
                        // Move the particle down the screen
                        particles[i].y += (particles[i].speed * 0.016)
                        
                        // If a particle is off-screen, reset it to the top
                        if particles[i].y > proxy.size.height + particles[i].size {
                            particles[i] = .create(in: proxy.size, sizeRange: self.sizeRange, speedRange: self.speedRange, withDelay: false)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// Helper extension to create new particles cleanly
private extension Particle {
    static func create(in size: CGSize, sizeRange: ClosedRange<Double>, speedRange: ClosedRange<Double>, withDelay: Bool) -> Particle {
        Particle(
            x: .random(in: 0...size.width),
            y: .random(in: -200...(-sizeRange.upperBound)), // Start above the screen
            size: .random(in: sizeRange),
            opacity: .random(in: 0.1...0.5),
            speed: .random(in: speedRange),
            initialDelay: withDelay ? .random(in: 0...5) : 0, // Stagger the start times
            rotation: .degrees(.random(in: -360...360))
        )
    }
}
