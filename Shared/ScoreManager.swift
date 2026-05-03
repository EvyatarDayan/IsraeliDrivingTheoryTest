import SwiftUI

class ScoreManager: ObservableObject {
    @Published var correctAnswers: Int = 0
    @Published var wrongAnswers: Int = 0
    @Published var completedTopics: Set<TopicSelectionView.Topic> = []
    @Published var completedCardsByTopic: [TopicSelectionView.Topic: Set<Int>] = [:]
    @Published var cardPositions: [TopicSelectionView.Topic: Int] = [:]
    @Published var savedCardOrders: [TopicSelectionView.Topic: [(String, String)]] = [:]
    @Published private var topicPoints: [TopicSelectionView.Topic: Int] = [:]
    @Published private var topicCorrectAnswers: [TopicSelectionView.Topic: Int] = [:]
    @Published private var topicWrongAnswers: [TopicSelectionView.Topic: Int] = [:]
    @Published var gameLanguage: WelcomeView.Language?
    @Published private var savedAnswerOptions: [TopicSelectionView.Topic: [Int: [(String, String)]]] = [:]
    @Published private var answeredSigns: [TopicSelectionView.Topic: [Int: (correct: Bool, selectedAnswer: String)]] = [:]
    
    var points: Int {
        topicPoints.values.reduce(0, +)
    }
    
    func reset() {
        correctAnswers = 0
        wrongAnswers = 0
        completedTopics.removeAll()
        completedCardsByTopic.removeAll()
        cardPositions.removeAll()
        savedCardOrders.removeAll()
        topicPoints.removeAll()
        topicCorrectAnswers.removeAll()
        topicWrongAnswers.removeAll()
        gameLanguage = nil
        savedAnswerOptions.removeAll()
        answeredSigns.removeAll()
    }
    
    func startNewTopic(_ topic: TopicSelectionView.Topic) {
        correctAnswers = topicCorrectAnswers[topic] ?? 0
        wrongAnswers = topicWrongAnswers[topic] ?? 0
    }
    
    func incrementCorrectAnswers(_ topic: TopicSelectionView.Topic) {
        correctAnswers += 1
        topicCorrectAnswers[topic, default: 0] += 1
    }
    
    func incrementWrongAnswers(_ topic: TopicSelectionView.Topic) {
        wrongAnswers += 1
        topicWrongAnswers[topic, default: 0] += 1
    }
    
    func getTopicCorrectAnswers(_ topic: TopicSelectionView.Topic) -> Int {
        return topicCorrectAnswers[topic] ?? 0
    }
    
    func getTopicWrongAnswers(_ topic: TopicSelectionView.Topic) -> Int {
        return topicWrongAnswers[topic] ?? 0
    }
    
    func markTopicAsCompleted(_ topic: TopicSelectionView.Topic) {
        completedTopics.insert(topic)
    }
    
    func markCardCompleted(_ cardIndex: Int, for topic: TopicSelectionView.Topic) {
        var topicCards = completedCardsByTopic[topic] ?? Set<Int>()
        topicCards.insert(cardIndex)
        completedCardsByTopic[topic] = topicCards
    }
    
    func getCompletedCards(for topic: TopicSelectionView.Topic) -> Set<Int> {
        return completedCardsByTopic[topic] ?? Set<Int>()
    }
    
    func saveCardPosition(_ position: Int, for topic: TopicSelectionView.Topic) {
        cardPositions[topic] = position
    }
    
    func getCardPosition(for topic: TopicSelectionView.Topic) -> Int {
        return cardPositions[topic] ?? 0
    }
    
    func saveCardOrder(_ cards: [(String, String)], for topic: TopicSelectionView.Topic) {
        savedCardOrders[topic] = cards
    }
    
    func getCardOrder(for topic: TopicSelectionView.Topic) -> [(String, String)]? {
        return savedCardOrders[topic]
    }
    
    func addPoints(_ points: Int, for topic: TopicSelectionView.Topic) {
        topicPoints[topic, default: 0] += points
    }
    
    func getTopicPoints(_ topic: TopicSelectionView.Topic) -> Int {
        return topicPoints[topic] ?? 0
    }
    
    func getSavedAnswerOptions(for topic: TopicSelectionView.Topic) -> [Int: [(String, String)]]? {
        return savedAnswerOptions[topic]
    }
    
    func saveAnswerOptions(_ options: [Int: [(String, String)]], for topic: TopicSelectionView.Topic) {
        savedAnswerOptions[topic] = options
    }
    
    func getAnsweredSigns(for topic: TopicSelectionView.Topic) -> [Int: (correct: Bool, selectedAnswer: String)]? {
        return answeredSigns[topic]
    }
    
    func saveAnsweredSigns(_ signs: [Int: (correct: Bool, selectedAnswer: String)], for topic: TopicSelectionView.Topic) {
        answeredSigns[topic] = signs
    }
    
    func clearTopicData(_ topic: TopicSelectionView.Topic) {
        completedTopics.remove(topic)
        completedCardsByTopic[topic] = []
        cardPositions[topic] = 0
        savedCardOrders.removeValue(forKey: topic)
        topicPoints[topic] = 0
        topicCorrectAnswers[topic] = 0
        topicWrongAnswers[topic] = 0
        savedAnswerOptions.removeValue(forKey: topic)
        answeredSigns.removeValue(forKey: topic)
        correctAnswers = 0
        wrongAnswers = 0
    }
} 


