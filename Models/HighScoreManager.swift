import Foundation
import SwiftUI

class HighScoreManager: ObservableObject {
    @Published private(set) var highScores: [HighScoreRecord] = []
    private let maxRecords = 10
    private let userDefaults = UserDefaults.standard
    private let storageKey = "highScores"
    
    init() {
        loadHighScores()
    }
    
    func checkAndAddNewScore(score: Int, mistakes: Int) -> Bool {
        let shouldAdd = highScores.count < maxRecords || score > (highScores.last?.score ?? 0)
        return shouldAdd
    }
    
    func addNewRecord(name: String, score: Int, mistakes: Int, timeTaken: Int? = nil) {
        let newRecord = HighScoreRecord(name: name, score: score, mistakes: mistakes, timeTaken: timeTaken)
        highScores.append(newRecord)
        highScores.sort { first, second in
            if first.score == second.score {
                if first.mistakes == second.mistakes {
                    // Rank by less timeTaken (faster is better)
                    switch (first.timeTaken, second.timeTaken) {
                    case let (a?, b?):
                        return a < b
                    case (nil, nil):
                        return false
                    case (nil, _?):
                        return false // nil is worse
                    case (_?, nil):
                        return true // non-nil is better
                    }
                }
                return first.mistakes < second.mistakes
            }
            return first.score > second.score
        }
        if highScores.count > maxRecords {
            highScores.removeLast()
        }
        saveHighScores()
    }
    
    private func loadHighScores() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([HighScoreRecord].self, from: data) {
            highScores = decoded
        }
    }
    
    private func saveHighScores() {
        if let encoded = try? JSONEncoder().encode(highScores) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
} 