import SwiftUI

private var isIPhone: Bool {
    UIDevice.current.userInterfaceIdiom == .phone
}

struct ScoreUpdateView: View {
    let points: Int
    let onComplete: () -> Void
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Text(points > 0 ? "+\(points)" : "\(points)")
            .font(.system(size: isIPhone ? 25 : 35, weight: .bold))
            .foregroundColor(points > 0 ? .green : .red)
            .padding(isIPhone ? 12 : 24)
            .background(
                RoundedRectangle(cornerRadius: isIPhone ? 40 : 40)
                    .fill(Color.white)
                    .opacity(0.9)
                    .shadow(radius: 5)
            )
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                // Fade in quickly
                withAnimation(.easeIn(duration: 0.1)) {
                    opacity = 1
                }
                
                // Start moving up immediately
                withAnimation(.easeOut(duration: 0.7)) {
                    offset = -70
                }
                
                // Start fade out slightly delayed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.4)) {
                        opacity = 0
                    }
                }
                
                // Cleanup
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    onComplete()
                }
            }
    }
} 