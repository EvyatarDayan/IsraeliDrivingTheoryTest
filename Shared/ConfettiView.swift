import SwiftUI
import AVFoundation

struct StarShape: Shape {
    let points: Int
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        
        var path = Path()
        let angleStep = .pi * 2 / Double(points * 2)
        
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * angleStep - .pi / 2
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

private var isIPhone: Bool {
    UIDevice.current.userInterfaceIdiom == .phone
}

struct ShinyStarParticle: View {
    let color: Color
    let angle: Double
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // Base star
            StarShape(points: 5)
                .fill(color)
            
            // Shiny overlay
            StarShape(points: 5)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: isIPhone ? 15 : 25, height: isIPhone ? 15 : 25)
        .rotationEffect(.degrees(angle))
        .scaleEffect(scale)
    }
}

struct ParticleSystem: View {
    @Binding var isActive: Bool
    let center: CGPoint
    
    let colors: [Color] = [
        .init(red: 1, green: 0, blue: 0),      // Bright Red
        .init(red: 0, green: 0, blue: 1),      // Bright Blue
        .init(red: 0, green: 1, blue: 0),      // Bright Green
        .init(red: 1, green: 1, blue: 0),      // Bright Yellow
        .init(red: 1, green: 0, blue: 1),      // Bright Magenta
        .init(red: 0, green: 1, blue: 1),      // Bright Cyan
        .init(red: 1, green: 0.5, blue: 0),    // Bright Orange
        .init(red: 0.5, green: 0, blue: 1),    // Bright Purple
    ]
    
    private let fireworkSound: AVAudioPlayer? = {
        guard let path = Bundle.main.path(forResource: "firework", ofType: "mp3") else { return nil }
        do {
            return try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        } catch {
            print("Could not create audio player: \(error)")
            return nil
        }
    }()
    
    @State private var particles: [(id: Int, position: CGPoint, angle: Double, scale: CGFloat, opacity: Double, color: Color, velocity: CGPoint, angularVelocity: Double)] = []
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                ShinyStarParticle(
                    color: particle.color,
                    angle: particle.angle,
                    scale: particle.scale
                )
                .position(particle.position)
                .opacity(particle.opacity)
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startConfetti()
            }
        }
    }
    
    private func startConfetti() {
        // Play firework sound
        fireworkSound?.currentTime = 0
        fireworkSound?.play()
        
        particles = (0..<150).map { id in
            let speed = Double.random(in: 400...800)
            let angle = Double.random(in: 0...360)
            let radians = angle * .pi / 180
            
            return (
                id: id,
                position: center,
                angle: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.3...1.0),
                opacity: 1.0,
                color: colors.randomElement() ?? .yellow,
                velocity: CGPoint(
                    x: cos(radians) * speed,
                    y: -abs(sin(radians) * speed) - 600
                ),
                angularVelocity: Double.random(in: 360...720)
            )
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.linear(duration: 0.016)) {
                updateParticles()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            timer?.invalidate()
            timer = nil
            isActive = false
            particles = []
        }
    }
    
    private func updateParticles() {
        particles = particles.map { particle in
            var newParticle = particle
            
            newParticle.position.x += particle.velocity.x * 0.016
            newParticle.position.y += particle.velocity.y * 0.016
            
            newParticle.velocity.y += 1500 * 0.016
            
            newParticle.velocity.x *= 0.97
            newParticle.velocity.y *= 0.97
            
            newParticle.angle += abs(particle.angularVelocity) * 0.016
            
            newParticle.angularVelocity *= 0.995
            
            newParticle.opacity -= 0.006
            
            return newParticle
        }.filter { $0.opacity > 0 }
    }
}

struct ConfettiAnimation: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ParticleSystem(
                isActive: $isVisible,
                center: CGPoint(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
            )
        }
    }
} 