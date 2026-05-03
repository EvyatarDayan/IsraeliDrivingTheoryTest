import SwiftUI
import AVFoundation

struct SignsGameView: View {
    @Environment(\.dismiss) private var dismiss  // Add this for navigation
    let userLanguage: WelcomeView.Language
    let topic: TopicSelectionView.Topic
    @ObservedObject var scoreManager: ScoreManager
    
    @State private var currentCardIndex = 0
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var answerOptions: [(String, String)] = []  // Array to hold answer options
    @State private var canMoveToNext = false  // Add this state variable
    @State private var completedCards: Set<Int> = []
    @State private var correctAnswer: String? = nil  // Add this to track correct answer
    @State private var wrongAnswer: String? = nil  // Add this to track wrong answer
    @State private var savedAnswerOptions: [Int: [(String, String)]] = [:]
    @State private var feedbackMessage: String? = nil
    @State private var showAnswerButtons = [false, false, false]  // Controls button animation
    @State private var showSoundButtons: [Bool] = [false, false, false]   // Track visibility of each sound button
    @State private var shuffledCards: [(String, String)] = []
    @State private var showConfetti = false
    @State private var correctCards: Set<Int> = []  // For immediate green coloring
    @State private var seenCards: Set<Int> = []  // Track which cards have been seen
    @State private var showScoreAnimation = false
    @State private var showCompletionPopup = false
    @State private var currentCardAttempts: Int = 0
    @State private var currentPoints: Int = 0  // Add this with other @State variables
    @State private var isGlowing = false
    @State private var glowingButtonIndex: Int? = nil
    @State private var previousCardIndex: Int = -1
    @State private var truncatedAnswers: Set<Int> = []  // Track which answers are truncated
    @State private var showFullTextPopup: (index: Int, text: String)? = nil  // Track which answer's full text to show
    @State private var feedbackTimer: Timer?
    @State private var answeredSigns: [Int: (correct: Bool, selectedAnswer: String)] = [:]
    
    // Hebrew letters for answers:
    let answerLetters = ["א", "ב", "ג"]
    
    var currentCards: [(String, String)] {
        shuffledCards
    }
    
    var currentImageName: String {
        guard !shuffledCards.isEmpty, currentCardIndex < shuffledCards.count else {
            return "placeholder"
        }
        return shuffledCards[currentCardIndex].0
    }
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // Add computed property to check if current card is completed
    private var isCurrentCardCompleted: Bool {
        completedCards.contains(currentCardIndex)
    }
    
    private func isTextTruncated(_ text: String, availableWidth: CGFloat, fontSize: CGFloat) -> Bool {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        return textWidth > availableWidth
    }
    
    var body: some View {
        ZStack {
            // Background
            Image("Road5")
                .resizable()
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    // Navigation buttons (Previous/Next)
                    HStack(spacing: 20) {
                        // Previous button
                        if currentCardIndex > 0 {
                            Button(action: {
                                currentCardIndex -= 1
                                scoreManager.saveCardPosition(currentCardIndex, for: topic)
                                generateAnswerOptions()
                                canMoveToNext = completedCards.contains(currentCardIndex)
                            }) {
                                Image("previous")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: isIPhone ? 110 : 220, height: isIPhone ? 70 : 120)
                                    .shadow(color: .black, radius: 8)
                                    .shadow(radius: 7)
                            }
                            .buttonStyle(NoAnimationButtonStyle())
                            .transition(.scaleAndFade)
                            .animation(.easeInOut, value: currentCardIndex)
                        }
                        
                        Spacer()
                        
                        // Next button
                        if let _ = correctAnswer, !(scoreManager.completedTopics.contains(topic) && currentCardIndex == shuffledCards.count - 1) {
                            Button(action: moveToNextCard) {
                                Image("next")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: isIPhone ? 110 : 220, height: isIPhone ? 70 : 120)
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
                    .position(x: geometry.size.width/2, y: isIPhone ? geometry.size.height * 0.40 : geometry.size.height * 0.29)
                    
                    // Card display
                    ZStack {
                        // Card background
                        RoundedRectangle(cornerRadius: isIPhone ? 10 : 15)
                            .fill(getCardBackgroundColor())
                            .frame(width: isIPhone ? geometry.size.width * 0.40 : geometry.size.width * 0.52,
                                   height: isIPhone ? geometry.size.height * 0.55 : geometry.size.height * 0.55)
                        
                        // Card image
                        Image(currentImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: isIPhone ? geometry.size.width * 0.40 : geometry.size.width * 0.47,
                                   height: isIPhone ? geometry.size.height * 0.50 : geometry.size.height * 0.50)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Answer buttons
                    VStack(spacing: isIPhone ? 12 : 15) {
                        ForEach(0..<3) { index in
                            if index < answerOptions.count {
                                HStack(spacing: 15) {
                                    let availableTextWidth = (isIPhone ? geometry.size.width * 0.7 : geometry.size.width * 0.7) - (isIPhone ? 30 : 50)
                                    let isTruncated = isTextTruncated(answerOptions[index].1, 
                                                                     availableWidth: availableTextWidth,
                                                                     fontSize: isIPhone ? 20 : 30)
                                    
                                    Button(action: {}) {
                                        Text("...")
                                            .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: isIPhone ? 50 : 90, height: isIPhone ? 40 : 70)
                                            .background(
                                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                    .fill(getButtonColor(for: answerOptions[index].1))
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
                                                if isTruncated {
                                                    showFullTextPopup = (index, answerOptions[index].1)
                                                }
                                            }
                                            .onEnded { _ in
                                                showFullTextPopup = nil
                                            }
                                    )
                                    .opacity(isTruncated ? 1 : 0.5)
                                    .opacity(showAnswerButtons[index] ? 1 : 0)
                                    
                                    // Main answer button
                                    Text(answerOptions[index].1)
                                        .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .padding(.horizontal, isIPhone ? 15 : 25)
                                        .frame(width: isIPhone ? geometry.size.width * 0.7 : geometry.size.width * 0.7,
                                               height: isIPhone ? 40 : 70)
                                        .background(
                                            RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                .fill(getButtonColor(for: answerOptions[index].1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                                        )
                                        .onTapGesture {
                                            if !completedCards.contains(currentCardIndex) {
                                                checkAnswer(answerOptions[index].1)
                                            }
                                        }
                                        .disabled(completedCards.contains(currentCardIndex))
                                        .opacity(shouldDimButton(answer: answerOptions[index].1) ? 0.7 : 1.0)
                                        .opacity(showAnswerButtons[index] ? 1 : 0)

                                    // New: Answer letter button
                                    Button(action: {
                                        if !completedCards.contains(currentCardIndex) {
                                            checkAnswer(answerOptions[index].1)
                                        }
                                    }) {
                                        Text(answerLetters[index])
                                            .font(.system(size: isIPhone ? 20 : 30, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: isIPhone ? 50 : 90, height: isIPhone ? 40 : 70)
                                            .background(
                                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                    .fill(getButtonColor(for: answerOptions[index].1))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: isIPhone ? 8 : 15)
                                                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 3 : 5)
                                            )
                                    }
                                    .buttonStyle(NoAnimationButtonStyle())
                                    .disabled(completedCards.contains(currentCardIndex))
                                    .opacity(showAnswerButtons[index] ? 1 : 0)
                                }
                            }
                        }
                    }
                    .padding(.top, isIPhone ? -10 : 30)
                    
                    Spacer()
                }
            }
            
            // Overlay elements (home button, score, etc.)
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
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
                                .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 4 : 5)
                        )
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .buttonStyle(NoAnimationButtonStyle())
                    
                    Spacer()
                    
                    ScoreView(scoreManager: scoreManager)
                }
                .padding(.top, 10)
                .padding(.horizontal, 30)
                
                ProgressCountView(
                    completedCount: currentCardIndex,
                    totalCount: currentCards.count,
                    isIPhone: isIPhone
                )
                .padding(.top, isIPhone ? -60 : -80)
                
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
                            .fill(message == "נכון מאוד!" ? Color.green : Color.red)
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
                SignCompletionPopup(
                    userLanguage: userLanguage,
                    topic: topic,
                    scoreManager: scoreManager,
                    onAppear: {
                        let soundFile = "CompletedTopicHe"
                        if let path = Bundle.main.path(forResource: soundFile, ofType: "mp3") {
                            do {
                                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                                audioPlayer?.play()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
                    },
                    action: {
                        dismiss()
                    }
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
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let savedOrder = scoreManager.getCardOrder(for: topic) {
                shuffledCards = savedOrder
            } else {
                shuffledCards = getCardsForTopic(topic).shuffled()
                scoreManager.saveCardOrder(shuffledCards, for: topic)
            }
            
            // Load saved answer options
            savedAnswerOptions = scoreManager.getSavedAnswerOptions(for: topic) ?? [:]
            
            // Load answered signs state
            answeredSigns = scoreManager.getAnsweredSigns(for: topic) ?? [:]
            
            completedCards = scoreManager.getCompletedCards(for: topic)
            correctCards = Set(answeredSigns.filter { $0.value.correct }.keys)
            
            let savedPosition = scoreManager.getCardPosition(for: topic)
            updateCardIndex(savedPosition)
            generateAnswerOptions()
            
            // If topic is completed, make all cards show as completed
            if scoreManager.completedTopics.contains(topic) {
                for index in 0..<shuffledCards.count {
                    completedCards.insert(index)
                    correctCards.insert(index)
                }
                canMoveToNext = true
            } else {
                scoreManager.startNewTopic(topic)
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            feedbackTimer?.invalidate()
            feedbackTimer = nil
        }
    }
    
    private func generateAnswerOptions() {
        guard currentCardIndex < currentCards.count else { return }
        
        // If we have saved answer options for this card, use them
        if let savedOptions = savedAnswerOptions[currentCardIndex] {
            answerOptions = savedOptions
        } else {
            // Get the current category's signs
            let currentCategoryAnswers = getCardsForTopic(topic).map { $0.1 }
            let wrongAnswers = currentCategoryAnswers.filter { $0 != currentCards[currentCardIndex].1 }
            
            // Randomly select 2 wrong answers
            var options = [currentCards[currentCardIndex].1]
            while options.count < 3 && !wrongAnswers.isEmpty {
                if let randomWrong = wrongAnswers.randomElement() {
                    if !options.contains(randomWrong) {
                        options.append(randomWrong)
                    }
                }
            }
            
            // Shuffle the options
            answerOptions = options.shuffled().map { (currentCards[currentCardIndex].0, $0) }
            
            // Save the options for this card
            savedAnswerOptions[currentCardIndex] = answerOptions
            scoreManager.saveAnswerOptions(savedAnswerOptions, for: topic)
        }
        
        // If the card was previously answered, restore its state
        if let answeredState = answeredSigns[currentCardIndex] {
            correctAnswer = currentCards[currentCardIndex].1
            if answeredState.correct {
                wrongAnswer = nil
            } else {
                wrongAnswer = answeredState.selectedAnswer
            }
            canMoveToNext = true
        } else if completedCards.contains(currentCardIndex) || correctCards.contains(currentCardIndex) {
            correctAnswer = currentCards[currentCardIndex].1
            canMoveToNext = true
            
            // Make sure it's marked as completed
            completedCards.insert(currentCardIndex)
            correctCards.insert(currentCardIndex)
        } else {
            correctAnswer = nil
            wrongAnswer = nil
            canMoveToNext = false
        }
        
        // Reset visibility states and animate
        showAnswerButtons = [false, false, false]
        
        // Animate answer buttons appearance
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation {
                    showAnswerButtons[i] = true
                }
            }
        }
    }
    
    private func playSound(soundFile: String) {
        if let path = Bundle.main.path(forResource: soundFile, ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.play()
            } catch {
                print("Could not play sound file: \(error)")
            }
        }
    }
    
    private func checkAnswer(_ selectedAnswer: String) {
        guard currentCardIndex < shuffledCards.count else { return }
        
        // Cancel any existing feedback timer
        feedbackTimer?.invalidate()
        feedbackTimer = nil
        
        isCorrect = selectedAnswer == shuffledCards[currentCardIndex].1
        currentCardAttempts += 1
        
        // Store the answer state
        answeredSigns[currentCardIndex] = (correct: isCorrect, selectedAnswer: selectedAnswer)
        scoreManager.saveAnsweredSigns(answeredSigns, for: topic)
        completedCards.insert(currentCardIndex)
        
        // Set feedback message
        withAnimation {
            if isCorrect {
                feedbackMessage = "נכון מאוד!"
            } else {
                // Find the correct answer index
                if let correctIndex = answerOptions.firstIndex(where: { $0.1 == shuffledCards[currentCardIndex].1 }) {
                    let answerLetters = ["א", "ב", "ג"]
                    let correctLetter = answerLetters[correctIndex]
                    feedbackMessage = "לא מדוייק, התשובה הנכונה היא: \(correctLetter)"
                } else {
                    feedbackMessage = "לא מדוייק, התשובה הנכונה מסומנת בירוק"
                }
            }
        }
        
        // Store the answer state and mark card as seen
        scoreManager.markCardCompleted(currentCardIndex, for: topic)
        
        if isCorrect {
            correctCards.insert(currentCardIndex)
            correctAnswer = selectedAnswer
            scoreManager.incrementCorrectAnswers(topic)
            
            // Award 1 point for correct answer
            currentPoints = 1
            scoreManager.addPoints(1, for: topic)
            
            // Play positive sound
            if let path = Bundle.main.path(forResource: "positive", ofType: "mp3") {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    audioPlayer?.play()
                } catch {
                    print("Could not play positive sound: \(error)")
                }
            }
            
            // Check if this was the last question and it was answered correctly
            if currentCardIndex == shuffledCards.count - 1 {
                // Add a 2-second delay before showing the completion popup
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    scoreManager.markTopicAsCompleted(topic)
                    showCompletionPopup = true
                }
            }
            
            // Show score animation
            withAnimation(.easeInOut(duration: 0.5)) {
                showScoreAnimation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showScoreAnimation = false
                }
            }
        } else {
            // Track wrong answer and show correct answer
            wrongAnswer = selectedAnswer
            correctAnswer = shuffledCards[currentCardIndex].1
            
            // Subtract 1 point for wrong answer
            currentPoints = -1
            scoreManager.addPoints(-1, for: topic)
            
            // Show score animation for negative points
            withAnimation(.easeInOut(duration: 0.5)) {
                showScoreAnimation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showScoreAnimation = false
                }
            }
            
            // Increment wrong answers counter
            scoreManager.incrementWrongAnswers(topic)
            
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
        
        // Enable next button after any answer
        canMoveToNext = true
        
        // Set up feedback timer
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
    }
    
    // Update the Next button action
    private func moveToNextCard() {
        // Cancel any existing feedback timer
        feedbackTimer?.invalidate()
        feedbackTimer = nil
        
        updateCardIndex(currentCardIndex + 1)
        scoreManager.saveCardPosition(currentCardIndex, for: topic)
        
        // Save the current state before moving
        scoreManager.saveAnswerOptions(savedAnswerOptions, for: topic)
        scoreManager.saveAnsweredSigns(answeredSigns, for: topic)
        
        correctAnswer = nil
        wrongAnswer = nil
        canMoveToNext = false
        currentCardAttempts = 0
        feedbackMessage = nil
        generateAnswerOptions()
        
        if !scoreManager.completedTopics.contains(topic) {
            checkTopicCompletion()
        }
    }
    
    // Add this function to check for topic completion
    private func checkTopicCompletion() {
        if completedCards.count == currentCards.count {
            scoreManager.markTopicAsCompleted(topic)
            
            // Show completion popup after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCompletionPopup = true
            }
        }
    }
    
    // Add helper function for button colors
    private func getButtonColor(for answer: String) -> Color {
        if let answeredState = answeredSigns[currentCardIndex] {
            if !answeredState.correct && answer == answeredState.selectedAnswer {
                return .red
            } else if answer == shuffledCards[currentCardIndex].1 {
                return .green
            }
        } else if answer == wrongAnswer {
            return .red
        } else if let correct = correctAnswer, answer == correct {
            return .green
        }
        return .blue
    }
    
    private func getCardsForTopic(_ topic: TopicSelectionView.Topic) -> [(String, String)] {
        switch topic {
        case .אזהרה:
            return AppData.signs["אזהרה והתראה"] ?? []
        case .הוריה:
            return AppData.signs["הוריה"] ?? []
        case .זכות:
            return AppData.signs["זכות קדימה"] ?? []
        case .איסורים:
            return AppData.signs["איסורים והגבלות"] ?? []
        case .מודיעין:
            return AppData.signs["מודיעין והדרכה"] ?? []
        case .רמזורים:
            return AppData.signs["רמזורים ובקרת נתיבים"] ?? []
        case .סימון:
            return AppData.signs["סימון על פני הדרך"] ?? []
        case .אתר:
            return AppData.signs["אתר עבודה"] ?? []
        }
    }
    
    // Add this helper function:
    private func shouldDimButton(answer: String) -> Bool {
        if let answeredState = answeredSigns[currentCardIndex] {
            if answeredState.correct {
                // For correct answers, dim all except the correct answer
                return answer != shuffledCards[currentCardIndex].1
            } else {
                // For wrong answers, dim all except the wrong and correct answers
                return answer != answeredState.selectedAnswer && answer != shuffledCards[currentCardIndex].1
            }
        } else if completedCards.contains(currentCardIndex) {
            // If card is completed but not in answeredSigns, dim all except the correct answer
            return answer != shuffledCards[currentCardIndex].1
        }
        return false  // Don't dim any buttons if the card hasn't been answered yet
    }
    
    private func getCardBackgroundColor() -> Color {
        if let answeredState = answeredSigns[currentCardIndex] {
            return answeredState.correct ? Color.green.opacity(0.9) : Color.red.opacity(0.9)
        } else if correctCards.contains(currentCardIndex) {
            return Color.green.opacity(0.9)
        }
        return Color.white.opacity(0.9)
    }
    
    private func updateCardIndex(_ newIndex: Int) {
        if currentCardIndex != newIndex && newIndex >= 0 && newIndex < shuffledCards.count {
            currentCardIndex = newIndex
            previousCardIndex = newIndex
            
            // Only play sound for new, uncompleted cards
            if !scoreManager.completedTopics.contains(topic) && 
               !seenCards.contains(newIndex) && 
               !answeredSigns.keys.contains(newIndex) &&
               !completedCards.contains(newIndex) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    playSound(soundFile: "newQuestion")
                }
                seenCards.insert(newIndex)
            }
        }
    }
}

extension AnyTransition {
    static var scaleAndFade: AnyTransition {
        .modifier(
            active: ScaleModifier(scale: 0),
            identity: ScaleModifier(scale: 1)
        ).combined(with: .opacity)
    }
    
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
}

struct ScaleModifier: ViewModifier {
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content.scaleEffect(scale)
    }
}


