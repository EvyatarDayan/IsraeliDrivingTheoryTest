import SwiftUI

struct ScoreView: View {
    @ObservedObject var scoreManager: ScoreManager
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var body: some View {
        HStack(spacing: 20) {
            Text("👍 \(scoreManager.correctAnswers)")
                .foregroundColor(.white)
            Text("👎 \(scoreManager.wrongAnswers)")
                .foregroundColor(.white)
        }
        .font(.system(size: isIPhone ? 15 : 25, weight: .bold))
        .frame(
            width: isIPhone ? 120 : 170,
            height: isIPhone ? 45 : 65
        )
        .background(Color.blue.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
        )
        .onAppear {
            print("nativeBounds: \(UIScreen.main.nativeBounds)")
        }
    }
} 
