import SwiftUI
import AVFoundation

struct TestGameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var highScoreManager: HighScoreManager
    let userLanguage: WelcomeView.Language
    @State private var startNewTest = false
    @State private var showHomeConfirmation = false
    
    @State private var currentQuestionIndex = 0
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var answerOptions: [String] = []
    @State private var canMoveToNext = false
    @State private var completedQuestions: Set<Int> = []
    @State private var correctAnswer: String? = nil
    @State private var wrongAnswer: String? = nil
    @State private var feedbackMessage: String? = nil
    @State private var feedbackTimer: Timer? = nil
    @State private var showAnswerButtons = [false, false, false, false]
    @State private var showConfetti = false
    @State private var correctQuestions: Set<Int> = []
    @State private var seenQuestions: Set<Int> = []
    @State private var showScoreAnimation = false
    @State private var showCompletionPopup = false
    @State private var currentQuestionAttempts: Int = 0
    @State private var currentPoints: Int = 0
    @State private var shuffledQuestions: [(question: String, number: String, answers: [String], correctAnswer: String)] = []
    @State private var currentShuffledAnswers: [String] = []
    @State private var truncatedAnswers: Set<Int> = []
    @State private var showFullTextPopup: (index: Int, text: String)? = nil
    @State private var showHighScoreInput = false
    @State private var highScoreInputLocked = false
    @State private var playerName = ""
    @State private var showQuestionImage = false
    @State private var answeredQuestions: [Int: (correct: Bool, selectedAnswer: String)] = [:]
    @State private var showTimerPopup = false
    @State private var isTimerEnabled = false
    @State private var timerSecondsRemaining = 40 * 60
    @State private var timer: Timer? = nil
    let answerLetters = ["א", "ב", "ג", "ד"]
    
    private let questionsPerTest = 30
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    private var currentQuestion: (question: String, number: String, answers: [String], correctAnswer: String)? {
        shuffledQuestions.indices.contains(currentQuestionIndex) ? shuffledQuestions[currentQuestionIndex] : nil
    }
    
    private func hasImage(for questionNumber: String) -> Bool {
        // Check if image exists in the asset catalog and print debug info
        let hasImage = UIImage(named: questionNumber) != nil
        print("Checking for image \(questionNumber): \(hasImage)")
        return hasImage
    }
    
    private func isTextTruncated(_ text: String, availableWidth: CGFloat, fontSize: CGFloat) -> Bool {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        return textWidth > availableWidth
    }
    
    private func getCompletionTitle() -> String {
        let correctAnswersCount = correctQuestions.count
        return correctAnswersCount >= 8 ? "עברת את המבחן יפה מאוד" : "נכשלת במבחן, נסה שוב"
    }
    
    private func resetTest() {
        currentQuestionIndex = 0
        correctAnswer = nil
        wrongAnswer = nil
        canMoveToNext = false
        showCompletionPopup = false
        showConfetti = false
        feedbackMessage = nil
        completedQuestions.removeAll()
        correctQuestions.removeAll()
        answeredQuestions.removeAll()
        seenQuestions.removeAll()
        currentQuestionAttempts = 0
        showScoreAnimation = false
    }
    
    var body: some View {
        ZStack {
            // Background
            Image("Road5")
                .resizable()
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ZStack {
                    // Navigation buttons (Previous/Next)
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            // Previous button
                            if currentQuestionIndex > 0 {
                                Button(action: {
                                    currentQuestionIndex -= 1
                                    generateAnswerOptions()
                                    canMoveToNext = completedQuestions.contains(currentQuestionIndex)
                                }) {
                                    Image("previous")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: isIPhone ? 100 : 200, height: isIPhone ? 60 : 100)
                                        .shadow(color: .black, radius: 8)
                                        .shadow(radius: 7)
                                }
                                .buttonStyle(NoAnimationButtonStyle())
                                .transition(.scaleAndFade)
                                .animation(.easeInOut, value: currentQuestionIndex)
                            }
                            Spacer()
                            
                            // Next button
                            if let _ = correctAnswer {
                                Button(action: {
                                    // Cancel any existing feedback timer
                                    feedbackTimer?.invalidate()
                                    feedbackTimer = nil
                                    
                                    currentQuestionIndex += 1
                                    correctAnswer = nil
                                    wrongAnswer = nil
                                    canMoveToNext = false
                                    currentQuestionAttempts = 0
                                    // Clear feedback message when moving to next question
                                    withAnimation(.easeInOut) {
                                        feedbackMessage = nil
                                    }
                                    generateAnswerOptions()
                                    checkTopicCompletion()
                                }) {
                                    Image("next")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: isIPhone ? 100 : 200, height: isIPhone ? 60 : 100)
                                        .shadow(color: .black, radius: 8)
                                        .shadow(radius: 7)
                                }
                                .buttonStyle(NoAnimationButtonStyle())
                                .transition(.slideAndFade)
                                .opacity(canMoveToNext ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5), value: canMoveToNext)
                                .disabled(!canMoveToNext)
                            }
                        }
                        .padding(.horizontal, isIPhone ? 30 : 50)
                        .position(x: geometry.size.width/2, y: isIPhone ? geometry.size.height * 0.30 : geometry.size.height * 0.30)
                        
                        Spacer()
                    }
                    
                    // Question display
                    if let question = currentQuestion {
                        ZStack {
                            // Question background
                            RoundedRectangle(cornerRadius: isIPhone ? 10 : 15)
                                .fill(getQuestionBackgroundColor())
                                .frame(width: isIPhone ? geometry.size.width * 0.50 : geometry.size.width * 0.50,
                                       height: isIPhone ? geometry.size.height * 0.45 : geometry.size.height * 0.35)
                                .overlay(
                                    RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                        .stroke(Color.black.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                                )
                            
                            ZStack {
                                // Question text
                                Text(question.question)
                                    .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(4)
                                    .padding(.horizontal, isIPhone ? 20 : 40)
                                    .frame(
                                        width: isIPhone ? geometry.size.width * 0.45 : geometry.size.width * 0.45,
                                        height: isIPhone ? geometry.size.height * 0.40 : geometry.size.height * 0.30
                                    )
                                
                                // Info button for questions with images
                                if let question = currentQuestion {
                                    HStack {
                                        Spacer()
                                        Button(action: {}) {
                                            Image("questionImage2")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: isIPhone ? 25 : 45, height: isIPhone ? 25 : 45)
                                                .frame(width: isIPhone ? 40 : 70, height: isIPhone ? 35 : 60)
                                                .background(
                                                    RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                        .fill(Color.blue)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                        .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                                                )
                                                .opacity(!question.number.isEmpty && hasImage(for: question.number) ? 1 : 0.5)
                                        }
                                        .buttonStyle(NoAnimationButtonStyle())
                                        .simultaneousGesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { _ in
                                                    if !question.number.isEmpty && hasImage(for: question.number) {
                                                        showQuestionImage = true
                                                    }
                                                }
                                                .onEnded { _ in
                                                    showQuestionImage = false
                                                }
                                        )
                                        .padding(.trailing, isIPhone ? -20 : -30)
                                    }
                                    .frame(
                                        width: isIPhone ? geometry.size.width * 0.50 : geometry.size.width * 0.50,
                                        height: isIPhone ? geometry.size.height * 0.45 : geometry.size.height * 0.35
                                    )
                                }
                            }
                        }
                        .position(x: geometry.size.width/2, y: isIPhone ? geometry.size.height * 0.30 : geometry.size.height * 0.25)
                    }
                    
                    // Answer buttons
                    VStack(spacing: isIPhone ? 12 : 15) {
                        ForEach(0..<4) { index in
                            if index < currentShuffledAnswers.count {
                                HStack(spacing: 15) {
                                    // Info button
                                    Button(action: {}) {
                                        Text("...")
                                            .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: isIPhone ? 50 : 90, height: isIPhone ? 33 : 70)
                                            .background(
                                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                    .fill(getButtonColor(for: currentShuffledAnswers[index]))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                                            )
                                    }
                                    .buttonStyle(NoAnimationButtonStyle())
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in
                                                if isTextTruncated(currentShuffledAnswers[index], availableWidth: (isIPhone ? geometry.size.width * 0.7 : geometry.size.width * 0.7) - (isIPhone ? 30 : 50), fontSize: isIPhone ? 20 : 30) {
                                                    showFullTextPopup = (index, currentShuffledAnswers[index])
                                                }
                                            }
                                            .onEnded { _ in
                                                showFullTextPopup = nil
                                            }
                                    )
                                    .opacity(isTextTruncated(currentShuffledAnswers[index], availableWidth: (isIPhone ? geometry.size.width * 0.7 : geometry.size.width * 0.7) - (isIPhone ? 30 : 50), fontSize: isIPhone ? 20 : 30) ? 1 : 0.5)
                                    .opacity(showAnswerButtons[index] ? 1 : 0)

                                    // Main answer button
                                    Text(currentShuffledAnswers[index])
                                        .font(.system(size: isIPhone ? 18 : 30, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .padding(.horizontal, isIPhone ? 15 : 25)
                                        .frame(width: isIPhone ? geometry.size.width * 0.7 : geometry.size.width * 0.7,
                                               height: isIPhone ? 33 : 70)
                                        .background(
                                            RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                .fill(getButtonColor(for: currentShuffledAnswers[index]))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                                        )
                                        .onTapGesture {
                                            if !completedQuestions.contains(currentQuestionIndex) {
                                                checkAnswer(currentShuffledAnswers[index])
                                            }
                                        }
                                        .background(
                                            GeometryReader { textGeometry in
                                                Color.clear.onAppear {
                                                    let font = UIFont.systemFont(ofSize: isIPhone ? 20 : 30, weight: .bold)
                                                    let text = currentShuffledAnswers[index]
                                                    let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
                                                    let availableWidth = (isIPhone ? geometry.size.width * 0.7 : geometry.size.width * 0.7) - (isIPhone ? 30 : 50)
                                                    DispatchQueue.main.async {
                                                        if textWidth > availableWidth {
                                                            truncatedAnswers.insert(index)
                                                        } else {
                                                            truncatedAnswers.remove(index)
                                                        }
                                                    }
                                                }
                                            }
                                        )
                                        .disabled(completedQuestions.contains(currentQuestionIndex))
                                        .opacity(shouldDimButton(answer: currentShuffledAnswers[index]) ? 0.7 : 1.0)
                                        .opacity(showAnswerButtons[index] ? 1 : 0)

                                    // New: Answer letter button
                                    Button(action: {
                                        if !completedQuestions.contains(currentQuestionIndex) {
                                            checkAnswer(currentShuffledAnswers[index])
                                        }
                                    }) {
                                        Text(answerLetters[index])
                                            .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: isIPhone ? 50 : 90, height: isIPhone ? 33 : 70)
                                            .background(
                                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                    .fill(getButtonColor(for: currentShuffledAnswers[index]))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                                            )
                                    }
                                    .buttonStyle(NoAnimationButtonStyle())
                                    .disabled(completedQuestions.contains(currentQuestionIndex))
                                    .opacity(showAnswerButtons[index] ? 1 : 0)
                                }
                            }
                        }
                    }
                    .position(x: geometry.size.width/2, y: isIPhone ? geometry.size.height * 0.80 : geometry.size.height * 0.75)
                }
            }
            
            // Overlay elements (home button, score, etc.)
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
                        .frame(width: isIPhone ? 120 : 170,
                               height: isIPhone ? 48 : 65)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 8 : 10)
                        )
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .buttonStyle(NoAnimationButtonStyle())
                    
                    Spacer()
                    
                    ProgressCountView(
                        completedCount: currentQuestionIndex,
                        totalCount: shuffledQuestions.count,
                        isIPhone: isIPhone
                    )
                    .padding(.top, isIPhone ? -5 : 25)
                    
                    Spacer()
                    
                    ScoreView(scoreManager: scoreManager)
                }
                .padding(.top, 10)
                .padding(.horizontal, 30)
                
                var isLargeIPhone: Bool {
                    UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height >= 2796
                }

                
                // Timer display below the score bar
                if isTimerEnabled {
                    GeometryReader { geometry in
                        Text(String(format: "%02d:%02d", timerSecondsRemaining / 60, timerSecondsRemaining % 60))
                            .font(.system(size: isIPhone ? 18 : 32, weight: .bold).monospacedDigit())
                            .foregroundColor(.black)
                            .frame(width: isIPhone ? 80 : 130, alignment: .center)
                            .padding(.horizontal, isIPhone ? 10 : 15)
                            .padding(.vertical, isIPhone ? 8 : 10)
                            .background(
                                RoundedRectangle(cornerRadius: isIPhone ? 10 : 15)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(radius: 5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: isIPhone ? 10 : 15)
                                    .stroke(Color.black.opacity(0.8), lineWidth: isIPhone ? 2 : 3)
                            )
                            .transition(.opacity)
                            .position(
                                x: geometry.size.width * 0.85,
                                y: isIPhone ? geometry.size.height * 1.6 : geometry.size.height * 3.2
                            )
                    }
                    .frame(height: 80)
                }
                Spacer()
            }
            
            // Feedback message
            if let message = feedbackMessage {
                Text(message)
                    .font(.system(size: isIPhone ? 32 : 50, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(isCorrect ? Color.green : Color.red)
                            .opacity(0.9)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 5)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: feedbackMessage)
                    .zIndex(2)
            }
            
            // Score animation overlay
            if showScoreAnimation {
                GeometryReader { geometry in
                    ScoreUpdateView(points: currentPoints) {
                        showScoreAnimation = false
                    }
                    .position(x: geometry.size.width - 110, y: 170)
                    .zIndex(1)
                }
            }
            
            // Completion popup
            if showCompletionPopup {
                GameCompletionPopup(
                    userLanguage: userLanguage,
                    scoreManager: scoreManager,
                    highScoreManager: highScoreManager,
                    onAppear: {
                        // Only play completion sounds and show confetti if passed
                        if correctQuestions.count >= 26 {
                            // Play completion sound
                            let soundFile = "testCompletedHe"
                            if let path = Bundle.main.path(forResource: soundFile, ofType: "mp3") {
                                do {
                                    audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                                    audioPlayer?.play()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                        showConfetti = true
                                        if let applausePath = Bundle.main.path(forResource: "applause", ofType: "mp3") {
                                            do {
                                                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: applausePath))
                                                audioPlayer?.play()
                                            } catch {
                                                print("Could not play applause sound: \(error)")
                                            }
                                        }
                                    }
                                } catch {
                                    print("Could not play sound file: \(error)")
                                }
                            }
                        }
                        // Check for new high score
                        let isNewHighScore = highScoreManager.checkAndAddNewScore(score: scoreManager.points, mistakes: scoreManager.wrongAnswers)
                        if isNewHighScore {
                            highScoreInputLocked = true
                            // Wait for confetti animation to finish before showing the high score popup and play the sound
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
                                if let path = Bundle.main.path(forResource: "newRecord", ofType: "mp3") {
                                    do {
                                        audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                                        audioPlayer?.play()
                                    } catch {
                                        print("Could not play newRecord sound: \(error)")
                                    }
                                }
                                showHighScoreInput = true
                            }
                        }
                        timer?.invalidate()
                        timer = nil
                    },
                    onNewTest: {
                        scoreManager.reset()
                        resetTest()
                        startNewTest = true
                    },
                    onClose: {
                        showCompletionPopup = false
                        dismiss()
                    },
                    buttonsDisabled: highScoreInputLocked
                )
            }
            
            // Confetti animation
            ConfettiAnimation(isVisible: $showConfetti)
                .allowsHitTesting(false)
            
            // Full text popup
            if let popup = showFullTextPopup {
                GeometryReader { geometry in
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Text(popup.text)
                            .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, isIPhone ? 15 : 25)
                            .padding(.vertical, isIPhone ? 10 : 20)
                            .background(
                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                    .fill(getButtonColor(for: popup.text))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                            )
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: geometry.size.width * 0.8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showFullTextPopup != nil)
            }
            
            // High Score Input Popup
            if showHighScoreInput {
                NewHighScorePopup(
                    score: scoreManager.points,
                    mistakes: scoreManager.wrongAnswers,
                    timeTaken: 40 * 60 - timerSecondsRemaining,
                    playerName: $playerName,
                    onSave: {
                        if !playerName.isEmpty {
                            let totalTestSeconds = 40 * 60
                            let timeTaken = totalTestSeconds - timerSecondsRemaining
                            highScoreManager.addNewRecord(
                                name: playerName,
                                score: scoreManager.points,
                                mistakes: scoreManager.wrongAnswers,
                                timeTaken: timeTaken
                            )
                            showHighScoreInput = false
                            highScoreInputLocked = false
                        }
                    }
                )
            }
            
            // Question image popup
            if let question = currentQuestion,
               showQuestionImage && 
               !question.number.isEmpty && 
               hasImage(for: question.number) {
                GeometryReader { geometry in
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Image(question.number)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: isIPhone ? geometry.size.width * 0.7 : geometry.size.width * 0.7)
                            .frame(maxHeight: isIPhone ? geometry.size.height * 0.8 : geometry.size.width * 0.5)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.black, lineWidth: 5)
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showQuestionImage)
            }
            
            // Timer Popup
            if showTimerPopup {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 5) {
                    Text("כמו מבחן אמיתי, מבחן זה יורכב מ-30 שאלות")
                        .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, isIPhone ? 15 : 30)
                    Text("שיבחרו אקראית ממאגר משרד התחבורה")
                        .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                        .foregroundColor(.black)
                    Text("המכיל 1802 שאלות.")
                        .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                        .foregroundColor(.black)
                    Text("-----------------------------------")
                        .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                        .foregroundColor(.black)
                    Text("מבחן אמיתי מוגבל ל-40 דקות,")
                        .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                        .foregroundColor(.black)
                    Text("מוכנים לאתגר? שנתחיל את השעון? ⏱️")
                        .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.bottom, isIPhone ? 15 : 30)
                    HStack(spacing: 40) {
                        Button(action: {
                            // No: just close popup
                            showTimerPopup = false
                        })
                        {
                            Text("בלי שעון")
                                .font(.system(size: isIPhone ? 24 : 36, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        Button(action: {
                            // Yes: enable timer
                            isTimerEnabled = true
                            showTimerPopup = false
                            startTimer()
                        })
                        {
                            Text("כן בטח")
                                .font(.system(size: isIPhone ? 24 : 36, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
   
                    }
                    .padding(.bottom, isIPhone ? 20 : 30)
                }
                .frame(maxWidth: isIPhone ? 500 : 700)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .transition(.scale)
                .zIndex(10)
            }
            
            NavigationLink(destination: TestGameView(
                scoreManager: scoreManager,
                highScoreManager: highScoreManager,
                userLanguage: userLanguage
            ), isActive: $startNewTest) {
                EmptyView()
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
        .onAppear {
            // Get all questions and shuffle them
            let allQuestions = AppData.questions["שאלות"] ?? []
            shuffledQuestions = Array(allQuestions.shuffled().prefix(questionsPerTest))
            generateAnswerOptions()
            if currentQuestionIndex == 0 {
                showTimerPopup = true
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            feedbackTimer?.invalidate()
            feedbackTimer = nil
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func generateAnswerOptions() {
        guard let currentQuestion = currentQuestion else { return }
        
        // Reset states for new questions
        if !completedQuestions.contains(currentQuestionIndex) {
            correctAnswer = nil
            wrongAnswer = nil
            canMoveToNext = false
        } else {
            // Restore state for completed questions
            if let answeredState = answeredQuestions[currentQuestionIndex] {
                if answeredState.correct {
                    correctAnswer = currentQuestion.correctAnswer
                    wrongAnswer = nil
                } else {
                    correctAnswer = currentQuestion.correctAnswer
                    wrongAnswer = answeredState.selectedAnswer
                }
                canMoveToNext = true
            }
        }
        
        // Shuffle the answers randomly
        currentShuffledAnswers = currentQuestion.answers.shuffled()
        
        // Reset visibility states and animate
        showAnswerButtons = [false, false, false, false]
        
        // Play new question sound only if this is a new question
        if !seenQuestions.contains(currentQuestionIndex) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if let path = Bundle.main.path(forResource: "newQuestion", ofType: "mp3") {
                    do {
                        audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                        audioPlayer?.play()
                    } catch {
                        print("Could not play new question sound: \(error)")
                    }
                }
            }
            seenQuestions.insert(currentQuestionIndex)
        }
        
        // Animate answer buttons appearance
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation {
                    showAnswerButtons[i] = true
                }
            }
        }
    }
    
    private func checkAnswer(_ selectedAnswer: String) {
        guard let currentQuestion = currentQuestion else { return }
        
        // Cancel any existing feedback timer
        feedbackTimer?.invalidate()
        feedbackTimer = nil
        
        isCorrect = selectedAnswer == currentQuestion.correctAnswer
        currentQuestionAttempts += 1
        
        // Store the answer state
        answeredQuestions[currentQuestionIndex] = (correct: isCorrect, selectedAnswer: selectedAnswer)
        completedQuestions.insert(currentQuestionIndex)
        
        if isCorrect {
            correctAnswer = selectedAnswer
            correctQuestions.insert(currentQuestionIndex)
            
            // Calculate points - only for correct answers
            scoreManager.addPoints(1, for: .אזהרה)
            currentPoints = 1
            scoreManager.correctAnswers += 1
            showScoreAnimation = true
            
            // Play positive sound
            if let path = Bundle.main.path(forResource: "positive", ofType: "mp3") {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    audioPlayer?.play()
                } catch {
                    print("Could not play positive sound: \(error)")
                }
            }
        } else {
            // Track wrong answer for button color and play sound
            wrongAnswer = selectedAnswer
            correctAnswer = currentQuestion.correctAnswer // Show correct answer
            
            // Increment wrong answers counter
            scoreManager.wrongAnswers += 1
            
            // Play negative sound
            if let path = Bundle.main.path(forResource: "negative", ofType: "mp3") {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    audioPlayer?.play()
                } catch {
                    print("Could not play sound file: \(error)")
                }
            }
        }
        
        // Enable next button immediately after any answer
        canMoveToNext = true
        
        // Set feedback message with animation
        withAnimation {
            if isCorrect {
                feedbackMessage = "נכון מאוד!"
            } else {
                if let correctIndex = currentShuffledAnswers.firstIndex(of: currentQuestion.correctAnswer) {
                    let answerLetters = ["א", "ב", "ג", "ד"]
                    let correctLetter = answerLetters[correctIndex]
                    feedbackMessage = "לא מדוייק, התשובה הנכונה היא: \(correctLetter)"
                } else {
                    feedbackMessage = "לא מדוייק, התשובה הנכונה מסומנת בירוק"
                }
            }
        }
        
        // Start new feedback timer
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [feedbackMessage] _ in
            // Only clear if the message hasn't changed
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    // Only clear if it's still the same message
                    if self.feedbackMessage == feedbackMessage {
                        self.feedbackMessage = nil
                    }
                }
            }
        }
        
        // Check if this is the last question
        if currentQuestionIndex == questionsPerTest - 1 {
            // Show completion popup after feedback message
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    feedbackMessage = nil  // Remove feedback message
                }
                showCompletionPopup = true
            }
        }
    }
    
    private func checkTopicCompletion() {
        if completedQuestions.count == questionsPerTest {
            showCompletionPopup = true
        }
    }
    
    private func getButtonColor(for answer: String) -> Color {
        if answer == wrongAnswer {
            return .red
        } else if let correct = correctAnswer, answer == correct {
            return .green
        }
        return .blue
    }
    
    private func shouldDimButton(answer: String) -> Bool {
        if completedQuestions.contains(currentQuestionIndex) {
            if let answeredState = answeredQuestions[currentQuestionIndex] {
                if answeredState.correct {
                    // For correct answers, dim all except the correct answer
                    return answer != currentQuestion?.correctAnswer
                } else {
                    // For wrong answers, dim all except the wrong and correct answers
                    return answer != answeredState.selectedAnswer && answer != currentQuestion?.correctAnswer
                }
            }
        }
        return false
    }
    
    private func getQuestionBackgroundColor() -> Color {
        if correctQuestions.contains(currentQuestionIndex) {
            return Color.green.opacity(0.9)
        } else if wrongAnswer != nil {
            return Color.red.opacity(0.9)
        } else {
            return Color.white.opacity(0.9)
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timerSecondsRemaining = 40 * 60
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timerSecondsRemaining > 0 {
                timerSecondsRemaining -= 1
            } else {
                timer?.invalidate()
                timer = nil
                // Optionally: handle timer end (e.g., show completion popup)
            }
        }
    }
}

struct NewHighScorePopup: View {
    let score: Int
    let mistakes: Int
    let timeTaken: Int
    @Binding var playerName: String
    let onSave: () -> Void
    var isIPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    var body: some View {
        VStack(spacing: isIPhone ? 5 : 20) {
            Text("שיא חדש!")
                .font(.system(size: isIPhone ? 24 : 40, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, isIPhone ? 10 : 20)
            Text("הקלד את שמך")
                .font(.system(size: isIPhone ? 18 : 28))
                .foregroundColor(.black)
            TextField("", text: $playerName)
                .onChange(of: playerName) { newValue in
                    if newValue.count > 12 {
                        playerName = String(newValue.prefix(12))
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .background(Color.gray)
                .font(.system(size: isIPhone ? 20 : 30))
                .frame(width: isIPhone ? 200 : 300)
            Text("נקודות: \(score) | פספוסים: \(mistakes)")
                .font(.system(size: isIPhone ? 18 : 28))
                .foregroundColor(.black)
            let minutes = timeTaken / 60
            let seconds = timeTaken % 60
            Text("זמן: " + String(format: "%02d:%02d", minutes, seconds))
                .font(.system(size: isIPhone ? 18 : 28))
                .foregroundColor(.black)
            Button(action: onSave) {
                Text("שמור")
                    .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: isIPhone ? 150 : 250, height: isIPhone ? 44 : 60)
                    .background(playerName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            .disabled(playerName.isEmpty)
        }
        .padding(isIPhone ? 20 : 30)
        .background(Color.yellow.opacity(0.9))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black, lineWidth: 5)
        )
        .padding(.horizontal, 40)
    }
} 
