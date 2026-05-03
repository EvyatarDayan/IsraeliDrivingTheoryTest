import SwiftUI

struct PieSlice: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.6  // Create donut hole
        
        // Outer arc
        path.move(to: center)
        path.addArc(center: center,
                   radius: radius,
                   startAngle: .degrees(startAngle - 90),
                   endAngle: .degrees(endAngle - 90),
                   clockwise: false)
        
        // Inner arc to create donut
        path.addArc(center: center,
                   radius: innerRadius,
                   startAngle: .degrees(endAngle - 90),
                   endAngle: .degrees(startAngle - 90),
                   clockwise: true)
        
        path.closeSubpath()
        return path
    }
}

struct ResultPieChart: View {
    let correctCount: Int
    let wrongCount: Int
    let size: CGFloat
    
    private var total: Int { correctCount + wrongCount }
    private var correctAngle: Double { Double(correctCount) / Double(total) * 360.0 }
    private var correctPercentage: Int { Int(Double(correctCount) / Double(total) * 100) }
    private var isAllCorrect: Bool { correctCount == total }
    private var isAllWrong: Bool { wrongCount == total }
    
    // Calculate position for text on the donut
    private func position(for count: Int, angle: Double) -> CGPoint {
        // Adjust radius to be between the center and the outer edge
        let radius = size * 0.5 * 0.79  // 40% of size * 0.8 to move inward
        let angleInRadians = (angle - 90) * .pi / 180.0
        let x = cos(angleInRadians) * radius
        let y = sin(angleInRadians) * radius
        return CGPoint(x: x, y: y)
    }
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var body: some View {
        ZStack {
            // Background circle for better visual effect
            Circle()
                .fill(Color.gray.opacity(0.1))
            
            // Wrong answers slice (red)
            PieSlice(startAngle: correctAngle, endAngle: 360)
                .fill(Color.red.opacity(0.7))
                .shadow(radius: 2)
            
            // Correct answers slice (green)
            PieSlice(startAngle: 0, endAngle: correctAngle)
                .fill(Color.green.opacity(0.7))
                .shadow(radius: 2)
            
            // Center circle with percentage
            Circle()
                .fill(Color.white)
                .frame( width: isIPhone ? size * 0.45 : size * 0.65, height: isIPhone ? size * 0.45 : size * 0.65)
                .shadow(radius: 2)
            
            // Percentage text in center
            VStack(spacing: 5) {
                Text("\(correctPercentage)%")
                    .font(.system(size: size * 0.13, weight: .bold))
                    .foregroundColor(.black)
                Text("הצלחה")
                    .font(.system(size: size * 0.08))
                    .foregroundColor(.black)
            }
            
            // Correct answers number - only show if not 100% correct or wrong
            if !isAllCorrect && !isAllWrong {
                Text("\(correctCount)")
                    .font(.system(size: size * 0.1, weight: .bold))
                    .foregroundColor(.white)
                    .position(
                        x: size/2 + position(for: correctCount, angle: correctAngle/2).x,
                        y: size/2 + position(for: correctCount, angle: correctAngle/2).y
                    )
                
                // Wrong answers number
                Text("\(wrongCount)")
                    .font(.system(size: size * 0.1, weight: .bold))
                    .foregroundColor(.white)
                    .position(
                        x: size/2 + position(for: wrongCount, angle: correctAngle + (360 - correctAngle)/2).x,
                        y: size/2 + position(for: wrongCount, angle: correctAngle + (360 - correctAngle)/2).y
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

struct GameCompletionPopup: View {
    let userLanguage: WelcomeView.Language
    let scoreManager: ScoreManager
    let highScoreManager: HighScoreManager
    let onAppear: () -> Void
    let onNewTest: () -> Void
    let onClose: () -> Void
    let buttonsDisabled: Bool
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: isIPhone ? 5 : 20) {  // Reduced spacing for iPhone
                Text(scoreManager.correctAnswers >= 26 ? "עברתם את המבחן, יפה מאוד" : "הפעם לא עברתם, נסו שוב")
                    .font(.system(size: isIPhone ? 24 : 40, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, isIPhone ? 10 : 20)  // Reduced top padding for iPhone
                
                // Pie Chart
                ResultPieChart(
                    correctCount: scoreManager.correctAnswers,
                    wrongCount: scoreManager.wrongAnswers,
                    size: isIPhone ? 140 : 200
                )
                .padding(.vertical, isIPhone ? 5 : 20)  // Reduced vertical padding for iPhone
                
                HStack(spacing: 20) {
                    Button(action: onNewTest) {
                        Text("מבחן חדש")
                            .font(.system(size: isIPhone ? 18 : 30, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: isIPhone ? 120 : 200, height: isIPhone ? 45 : 70)  // Reduced height for iPhone
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                            )
                    }
                    .disabled(buttonsDisabled)
                    
                    Button(action: onClose) {
                        Text("סגור")
                            .font(.system(size: isIPhone ? 18 : 30, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: isIPhone ? 120 : 200, height: isIPhone ? 45 : 70)  // Reduced height for iPhone
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                            )
                    }
                    .disabled(buttonsDisabled)
                }
                .padding(.top, isIPhone ? 5 : 20)  // Reduced top padding for iPhone
                .padding(.bottom, isIPhone ? 10 : 20)  // Reduced bottom padding for iPhone
                .buttonStyle(NoAnimationButtonStyle())
            }
            
            .padding(isIPhone ? 20 : 30)  // Reduced overall padding for iPhone
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black, lineWidth: 5)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            onAppear()
        }
    }
} 
