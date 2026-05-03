import SwiftUI

struct ClearPointsPopup: View {
    let userLanguage: WelcomeView.Language
    let topic: TopicSelectionView.Topic
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("למחוק את הנתונים?")
                    .font(.system(size: isIPhone ? 24 : 40, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("כל הניקוד של נושא זה ימחק!")
                    .font(.system(size: isIPhone ? 18 : 30))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button(action: onConfirm) {
                        Text("אישור")
                            .font(.system(size: isIPhone ? 20 : 35, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: isIPhone ? 120 : 200, height: isIPhone ? 45 : 70)
                            .background(Color.red)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                    }
                    
                    Button(action: onCancel) {
                        Text("ביטול")
                            .font(.system(size: isIPhone ? 20 : 35, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: isIPhone ? 120 : 200, height: isIPhone ? 45 : 70)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                    }
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
}
