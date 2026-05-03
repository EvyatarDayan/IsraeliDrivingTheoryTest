import SwiftUI

struct SignCompletionPopup: View {
    let userLanguage: WelcomeView.Language
    let topic: TopicSelectionView.Topic
    let scoreManager: ScoreManager
    let onAppear: () -> Void
    let action: () -> Void
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: isIPhone ? 5 : 20) {
                Text("הנושא הושלם, יפה מאוד!")
                    .font(.system(size: isIPhone ? 24 : 40, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 5) {
                    // Pie Chart
                    ResultPieChart(
                        correctCount: scoreManager.correctAnswers,
                        wrongCount: scoreManager.wrongAnswers,
                        size: isIPhone ? 140 : 200
                    )
                    .padding(.vertical, 5)
                }
                .padding(.vertical, 5)
                
                Button(action: action) {
                    HStack(spacing: 20) {
                        Image("home")
                            .resizable()
                            .scaledToFit()
                            .frame(width: isIPhone ? 25 : 38)
                        Text("חזרה")
                            .font(.system(size: isIPhone ? 18 : 30, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: isIPhone ? 200 : 300, height: isIPhone ? 50 : 70)
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                    )
                }
            }
            .buttonStyle(NoAnimationButtonStyle())
            .padding(30)
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
