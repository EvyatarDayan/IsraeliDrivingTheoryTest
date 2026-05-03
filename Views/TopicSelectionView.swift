import SwiftUI
import ACarousel
import AVFoundation

struct TopicSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let userLanguage: WelcomeView.Language
    @State private var selectedTopic: Topic?
    @State private var isNavigatingToGame = false
    @State private var currentIndex: Int = 0
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var highScoreManager: HighScoreManager
    @State private var showGameCompletionPopup = false
    @State private var showConfetti = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showClearAlert = false
    @State private var topicToReset: Topic?
    @State private var isAlertShowing = false
    @State private var showHomeConfirmation = false
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    enum Topic: CaseIterable, Identifiable {
        case אזהרה
        case הוריה
        case זכות
        case איסורים
        case מודיעין
        case רמזורים
        case סימון
        case אתר
        
        var id: Self { self }
        
        var imageName: String {
            switch self {
            case .אזהרה: return "TopicOne"
            case .הוריה: return "TopicTwo"
            case .זכות: return "TopicThree"
            case .איסורים: return "TopicFour"
            case .מודיעין: return "TopicSix"
            case .רמזורים: return "TopicSeven"
            case .סימון: return "TopicEight"
            case .אתר: return "TopicNine"
//            case .סמלים: return "TopicTen"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Main content
            ZStack {
                Image("Road4")
                    .resizable()
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack {
                        Text(userLanguage == .english ? "Select a topic" : "בחרו נושא")
//                            .font(isIPhone ? .title2 : .largeTitle)
                            .font(.system(size: isIPhone ? 24 : 50, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 8)
                            .shadow(radius: 7)
                        
                        ACarousel(Topic.allCases,
                                 index: $currentIndex,
                                 spacing: isIPhone ? geometry.size.width * 0.02 : geometry.size.width * 0.02,
                                 headspace: isIPhone ? geometry.size.width * 0.2 : geometry.size.width * 0.2,
                                 sidesScaling: 1.0,
                                 isWrap: true,
                                 autoScroll: .inactive) { topic in
                            TopicCard(topic: topic,
                                     userLanguage: userLanguage,
                                      cardHeight: isIPhone ? geometry.size.height * 0.55 : geometry.size.height * 0.5,
                                      scoreManager: scoreManager,
                                      isAlertShowing: $isAlertShowing,
                                      showClearAlert: $showClearAlert,
                                      topicToReset: $topicToReset)
                                .scaleEffect(topic == Topic.allCases[currentIndex] ? 1.0 : 0.7)
                                .animation(.easeInOut, value: currentIndex)
                                .onTapGesture {
                                    if !showClearAlert {
                                        selectedTopic = topic
                                        if let index = Topic.allCases.firstIndex(of: topic) {
                                            currentIndex = index
                                        }
                                        isNavigatingToGame = true
                                    }
                                }
                        }
                        .disabled(showClearAlert || isAlertShowing)
                        .onChange(of: currentIndex) { _ in
                            // Play sound when topic changes
                            if let path = Bundle.main.path(forResource: "topicSelect1", ofType: "mp3") {
                                do {
                                    audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                                    audioPlayer?.play()
                                } catch {
                                    print("Could not play sound file: \(error)")
                                }
                            }
                        }
                        .frame(height: isIPhone ? 300 : geometry.size.height * 0.7)
                    }
                    .position(x: geometry.size.width/2,
                             y: geometry.size.height * 0.50)
                }
            }
            
            // Overlay home and score buttons
            VStack {
                HStack {
                    Button(action: {
                        showHomeConfirmation = true
                    }) {
                        HStack(spacing: 10) {
                            Image("home")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIPhone ? 25 : 38)
                        }
                        .foregroundColor(.white)
                        .frame(
                            width: isIPhone ? 120 : 170,
                            height: isIPhone ? 48 : 65
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 8 : 10)
                        )
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .buttonStyle(NoAnimationButtonStyle())
                    .disabled(showClearAlert || isAlertShowing)
                    
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.horizontal, 30)
                Spacer()
            }
            
            // Add game completion popup
            if showGameCompletionPopup {
                GameCompletionPopup(
                    userLanguage: userLanguage,
                    scoreManager: scoreManager,
                    highScoreManager: highScoreManager,
                    onAppear: {
                        // Play completion sound
                        let soundFile = "testCompletedHe3"
                        if let path = Bundle.main.path(forResource: soundFile, ofType: "mp3") {
                            do {
                                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                                audioPlayer?.play()
                            } catch {
                                print("Could not play sound file: \(error)")
                            }
                        }
                    },
                    onNewTest: {
                        scoreManager.reset()
                        dismiss()
                    },
                    onClose: {
                        dismiss()
                    },
                    buttonsDisabled: false
                )
            }
            
            ConfettiAnimation(isVisible: $showConfetti)
                .allowsHitTesting(false)
                
            // Add the clear points popup at the root level
            if showClearAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    ClearPointsPopup(
                        userLanguage: userLanguage,
                        topic: topicToReset ?? .אזהרה,  // Provide a default value
                        onConfirm: {
                            if let topic = topicToReset {
                                scoreManager.clearTopicData(topic)
                            }
                            showClearAlert = false
                            topicToReset = nil
                        },
                        onCancel: {
                            showClearAlert = false
                            topicToReset = nil
                        }
                    )
                }
            }
            
            // Add home confirmation popup
            if showHomeConfirmation {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                        VStack(spacing: 30) {
                            Text("האם אתם בטוחים?\nהניקוד הקיים ימחק!")
                                .font(.system(size: isIPhone ? 22 : 35, weight: .bold))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, isIPhone ? 30 : 40)
                            
                            HStack(spacing: 30) {
                                Button(action: {
                                    showHomeConfirmation = false
                                }) {
                                    Text("לא")
                                        .font(.system(size: isIPhone ? 22 : 35, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 40)
                                        .padding(.vertical, 16)
                                        .background(Color.red)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    showHomeConfirmation = false
                                    scoreManager.reset()
                                    dismiss()
                                }) {
                                    Text("כן")
                                        .font(.system(size: isIPhone ? 22 : 35, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 40)
                                        .padding(.vertical, 16)
                                        .background(Color.green)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.bottom, isIPhone ? 30 : 40)
                        }
                        .frame(maxWidth: isIPhone ? 350 : 450)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .transition(.scale)
                        .zIndex(10)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isNavigatingToGame) {
            if let topic = selectedTopic {
                SignsGameView(userLanguage: userLanguage, topic: topic, scoreManager: scoreManager)
            }
        }
        .onAppear {
            // Check if all topics are completed
            if scoreManager.completedTopics.count == Topic.allCases.count {
                showGameCompletionPopup = true
            }
        }
    }
}

private var isIPhone: Bool {
    UIDevice.current.userInterfaceIdiom == .phone
}

struct TopicCard: View {
    let topic: TopicSelectionView.Topic
    let userLanguage: WelcomeView.Language
    let cardHeight: CGFloat
    @ObservedObject var scoreManager: ScoreManager
    @Binding var isAlertShowing: Bool
    @Binding var showClearAlert: Bool
    @Binding var topicToReset: TopicSelectionView.Topic?
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    private func getTopicCardCount() -> Int {
        switch topic {
        case .אזהרה: return 52
        case .הוריה: return 31
        case .זכות: return 12
        case .איסורים: return 41
        case .מודיעין: return 37
        case .רמזורים: return 29
        case .סימון: return 21
        case .אתר: return 35
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                ZStack {
                    Image(topic.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: cardHeight)
                        .cornerRadius(5)
                        .shadow(radius: 5)
                    
                    let completedCount = scoreManager.getCompletedCards(for: topic).count
                    if completedCount > 0 && !scoreManager.completedTopics.contains(topic) {
                        VStack {
                            ProgressCountView(
                                completedCount: completedCount,  // Use the actual completed count without subtracting 1
                                totalCount: getTopicCardCount(),
                                isIPhone: isIPhone
                            )
                            Spacer()
                        }
                        .padding(.top, isIPhone ? 20 : 40)
                    }
                    
                    if scoreManager.completedTopics.contains(topic) {
                        ZStack {
                            Image("CompletedTopic")
                                .resizable()
                                .scaledToFit()
                                .frame(height: cardHeight * 0.8)
                                .opacity(0.9)
                                .cornerRadius(15)
                            
                            VStack {
                                HStack(spacing: 5) {
                                    Text("\(scoreManager.wrongAnswers) פספוסים")
                                        .font(.system(size: isIPhone ? 15 : 30, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 5)
                                        .background(Color.red.opacity(0.7))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: isIPhone ? 8 : 12)
                                                .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 4 : 5)
                                        )
                                    Text("\(scoreManager.correctAnswers) נקודות")
                                        .font(.system(size: isIPhone ? 15 : 30, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 5)
                                        .background(Color.green.opacity(0.7))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: isIPhone ? 8 : 12)
                                                .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 4 : 5)
                                        )
                                    Button(action: {
                                        topicToReset = topic
                                        showClearAlert = true
                                    }) {
                                        Image(systemName: "trash.circle.fill")
                                            .font(.system(size: isIPhone ? 20 : 45))
                                            .foregroundColor(.red)
                                            .background(Color.white.opacity(0.8))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(.top, isIPhone ? -100 : -200)
                        }
                    }
                }
                .frame(height: cardHeight)
                
                Text(userLanguage == .english ? hebrewTopicTitle(for: topic) : hebrewTopicTitle(for: topic))
                    .font(.system(size: isIPhone ? 22 : 50, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .allowsHitTesting(!showClearAlert)
        }
    }
    
    private func hebrewTopicTitle(for topic: TopicSelectionView.Topic) -> String {
        switch topic {
        case .אזהרה: return "אזהרה והתראה"
        case .הוריה: return "הוריה"
        case .זכות: return "זכות קדימה"
        case .איסורים: return "איסורים והגבלות"
        case .מודיעין: return "מודיעין והדרכה"
        case .רמזורים: return "רמזורים ובקרת נתיבים"
        case .סימון: return "סימון על פני הדרך"
        case .אתר: return "אתר עבודה"
        }
    }
} 
