import SwiftUI
import AVFoundation

struct WelcomeView: View {
    @StateObject private var scoreManager = ScoreManager()
    @StateObject private var highScoreManager = HighScoreManager()
    @State private var showHighScores = false
    @State private var showNewGameAlert = false
    @State private var selectedLanguage: Language?
    @State private var isNavigatingToTopics = false
    @State private var showCustomAlert = false
    @State private var showHebrew = false
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var audioPlayer: AVAudioPlayer?
    
    enum Language {
        case english
        case hebrew
    }
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    private var flagBaseSize: CGFloat {
        isIPhone ? 60 : 120  // Base size - adjust this number to scale both flags
    }
    
    private var flagWidth: CGFloat { 
        isIPhone ? 250 : 400  // Customized width for both devices
    }
    
    private var flagHeight: CGFloat { 
        isIPhone ? 150 : 250  // Customized height for both devices
    }
    
    private var isGameInProgress: Bool {
        !scoreManager.completedCardsByTopic.isEmpty
    }
    
    private var shouldShowContinueButton: Bool {
        isGameInProgress && 
        scoreManager.completedTopics.count < TopicSelectionView.Topic.allCases.count &&
        selectedLanguage == scoreManager.gameLanguage  // Only show if languages match
    }

    private func playTrophySound() {
        if let path = Bundle.main.path(forResource: "highScore1", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.play()
            } catch {
                print("Could not play sound file: \(error)")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("highwayBackground")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation {
                                if !showHighScores {  // Only play sound when opening
                                    playTrophySound()
                                    showHighScores = true  // Only allow opening, not closing
                                }
                            }
                        }) {
                            Image("Trophy1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIPhone ? 40 : 60)
                        }
                        .buttonStyle(NoAnimationButtonStyle())
                        .disabled(showHighScores)
                        .padding(.top, isIPhone ? 40 : 20)
                        .padding(.leading, isIPhone ? -10 : 30)
                        
                        Spacer()
                    }
                    Spacer()
                }
                
                VStack(spacing: isIPhone ? -30 : 30) {
                    Text("לומדים תיאוריה בקלות")
                    // This is the language view title font
                        .font(.system(size: isIPhone ? 50 : 90))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 50)
                        .shadow(color: .black, radius: 8)
                        .shadow(radius: 7)
                    
                    HStack(spacing: 30) {
                        Button(action: {
                            selectedLanguage = .english
                            isNavigatingToTopics = true
                            scoreManager.reset()  // Reset scores when selecting English
                        }) {
                            ZStack {
                                // Button background with depth
                                RoundedRectangle(cornerRadius: isIPhone ? 15 : 25)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#2c3e50"),
                                                Color(hex: "#3498db")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: flagWidth, height: flagHeight)
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: isIPhone ? 15 : 25)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    )
                                    .opacity(0.7)
                                
                                // Inner shadow for depth
                                RoundedRectangle(cornerRadius: isIPhone ? 15 : 25)
                                    .fill(Color.black.opacity(0.1))
                                    .frame(width: flagWidth - 4, height: flagHeight - 4)
                                    .blur(radius: 2)
                                
                                Text("תרגול\nמבחן אמיתי")  // Split into two lines
                                    .font(.system(size: isIPhone ? 30 : 50))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)  // Center align multiline text
                                    .lineSpacing(isIPhone ? 5 : 10)  // Add space between lines
                                    .padding(.horizontal, isIPhone ? 15 : 25)  // Add horizontal padding
                                    .frame(maxWidth: flagWidth * 0.9)  // Constrain text width
                                    .shadow(color: .black, radius: 8)
                                    .shadow(radius: 7)
                            }
                        }
                        .buttonStyle(NoAnimationButtonStyle())
                        .padding()
                        
                        Button(action: {
                            selectedLanguage = .hebrew
                            isNavigatingToTopics = true
                            scoreManager.reset()  // Reset scores when selecting Hebrew
                        }) {
                            ZStack {
                                // Button background with depth
                                RoundedRectangle(cornerRadius: isIPhone ? 15 : 25)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#2c3e50"),
                                                Color(hex: "#3498db")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: flagWidth, height: flagHeight)
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: isIPhone ? 15 : 25)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    )
                                    .opacity(0.7)
                                
                                // Inner shadow for depth
                                RoundedRectangle(cornerRadius: isIPhone ? 15 : 25)
                                    .fill(Color.black.opacity(0.1))
                                    .frame(width: flagWidth - 4, height: flagHeight - 4)
                                    .blur(radius: 2)
                                
                                Text("תרגול\nתמרורים")
                                    .font(.system(size: isIPhone ? 30 : 50))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)  // Center align multiline text
                                    .lineSpacing(isIPhone ? 5 : 10)  // Add space between lines
                                    .shadow(color: .black, radius: 8)
                                    .shadow(radius: 7)
                            }
                        }
                        .buttonStyle(NoAnimationButtonStyle())
                        .padding()
                    }
                    
                    // Continue Game Button (only show if game in progress)
                    if shouldShowContinueButton {
                        HStack {
                            Spacer()
                            NavigationLink(destination: TopicSelectionView(
                                userLanguage: selectedLanguage ?? .english, 
                                scoreManager: scoreManager,
                                highScoreManager: highScoreManager
                            )) {
                                Text(selectedLanguage == .hebrew 
                                    ? "המשך"
                                    : (selectedLanguage == .english ? "Continue" : "Fortsätt spela"))
                                    .font(.system(size: isIPhone ? 22 : 40, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: isIPhone ? 180 : 300, height: isIPhone ? 60 : 80)
                                    .background(Color.green.opacity(0.9))
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 4 : 8)
                                    )
                            }
                            .buttonStyle(NoAnimationButtonStyle())
                            .onAppear {
                                scoreManager.reset()  // Reset scores when continuing game
                            }
                            Spacer()
                        }
                    }
                }
                .disabled(showHighScores)
                
                if showCustomAlert {
                    CustomLanguageAlert(
                        userLanguage: selectedLanguage ?? .english,
                        onConfirm: {
                            scoreManager.reset()
                            scoreManager.gameLanguage = selectedLanguage
                            showCustomAlert = false
                            isNavigatingToTopics = true  // Navigate directly to topics
                        },
                        onCancel: {
                            showCustomAlert = false
                        }
                    )
                }
                
                if showHighScores {
                    HighScoreView(
                        userLanguage: selectedLanguage ?? .english,
                        highScoreManager: highScoreManager,
                        isPresented: $showHighScores
                    )
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .animation(.easeInOut(duration: 0.3), value: showHighScores)
                }
            }
            .navigationDestination(isPresented: $isNavigatingToTopics) {
                if let language = selectedLanguage {
                    if language == .english {
                        TestGameView(
                            scoreManager: scoreManager,
                            highScoreManager: highScoreManager,
                            userLanguage: language
                        )
                    } else {
                        TopicSelectionView(
                            userLanguage: language,
                            scoreManager: scoreManager,
                            highScoreManager: highScoreManager
                        )
                    }
                }
            }
        }
    }
}

struct CustomLanguageAlert: View {
    let userLanguage: WelcomeView.Language
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
                Text("להתחיל משחק חדש?")
                    .font(.system(size: isIPhone ? 24 : 40, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("כל הנקודות ימחקו")
                    .font(.system(size: isIPhone ? 20 : 30))
                    .foregroundColor(.black)
                    .padding(.bottom, 10)
                
                HStack(spacing: 20) {
                    Button(action: onCancel) {
                        Text("ביטול")
                            .font(.system(size: isIPhone ? 18 : 30, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: isIPhone ? 120 : 200, height: isIPhone ? 50 : 70)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                            )
                    }
                    
                    Button(action: onConfirm) {
                        Text("התחילו חדש")
                            .font(.system(size: isIPhone ? 18 : 30, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: isIPhone ? 120 : 200, height: isIPhone ? 50 : 70)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                            )
                    }
                }
            }
            .padding(30)
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black, lineWidth: 5)
            )
            .padding(.horizontal, 40)
        }
    }
}

struct NoAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .animation(nil, value: configuration.isPressed)  // Explicitly disable animation
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
