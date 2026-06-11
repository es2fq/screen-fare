//
//  Challenges.swift
//  screenfare
//
//  Challenge type system and implementations for Math, Typing, and Memory challenges
//

import Foundation

// MARK: - Challenge Type System

enum ChallengeType: String, CaseIterable {
    case math = "Math"
    case typing = "Typing"
    case memory = "Memory"

    var isPro: Bool {
        switch self {
        case .math: return false
        case .typing, .memory: return true
        }
    }
}

protocol Challenge {
    var type: ChallengeType { get }
    var questionText: String { get }
}

enum ChallengeDifficulty: String, CaseIterable {
    case veryEasy = "Very Easy"
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case veryHard = "Very Hard"
}

enum MathOperation: String, CaseIterable {
    case addition = "+"
    case multiplication = "×"

    func calculate(_ a: Int, _ b: Int) -> Int {
        switch self {
        case .addition: return a + b
        case .multiplication: return a * b
        }
    }
}

struct MathChallenge: Challenge {
    let firstNumber: Int
    let secondNumber: Int
    let thirdNumber: Int?
    let operation: MathOperation
    let secondOperation: MathOperation?
    let correctAnswer: Int

    var type: ChallengeType { .math }

    var questionText: String {
        // Medium: three number addition
        if let third = thirdNumber, secondOperation != nil {
            return "\(firstNumber) \(operation.rawValue) \(secondNumber) \(secondOperation!.rawValue) \(third) = ?"
        }
        // Hard/Very Hard: compound operation with parentheses
        else if let secondOp = secondOperation {
            return "(\(firstNumber) \(operation.rawValue) \(secondNumber)) \(secondOp.rawValue) \(thirdNumber ?? 0) = ?"
        }
        // Very Easy/Easy: simple two number addition
        else {
            return "\(firstNumber) \(operation.rawValue) \(secondNumber) = ?"
        }
    }

    init(difficulty: ChallengeDifficulty = .medium) {
        switch difficulty {
        case .veryEasy:
            // Single digit addition (1-9)
            firstNumber = Int.random(in: 1...9)
            secondNumber = Int.random(in: 1...9)
            thirdNumber = nil
            operation = .addition
            secondOperation = nil
            correctAnswer = firstNumber + secondNumber

        case .easy:
            // Double digit addition (10-99)
            firstNumber = Int.random(in: 10...99)
            secondNumber = Int.random(in: 10...99)
            thirdNumber = nil
            operation = .addition
            secondOperation = nil
            correctAnswer = firstNumber + secondNumber

        case .medium:
            // Three double digit addition (10-99 + 10-99 + 10-99)
            firstNumber = Int.random(in: 10...99)
            secondNumber = Int.random(in: 10...99)
            thirdNumber = Int.random(in: 10...99)
            operation = .addition
            secondOperation = .addition
            correctAnswer = firstNumber + secondNumber + thirdNumber!

        case .hard:
            // (single digit × double digit) + double digit
            firstNumber = Int.random(in: 1...9)
            secondNumber = Int.random(in: 10...99)
            thirdNumber = Int.random(in: 10...99)
            operation = .multiplication
            secondOperation = .addition
            let multiplicationResult = firstNumber * secondNumber
            correctAnswer = multiplicationResult + thirdNumber!

        case .veryHard:
            // (double digit × double digit) + triple digit
            firstNumber = Int.random(in: 10...99)
            secondNumber = Int.random(in: 10...99)
            thirdNumber = Int.random(in: 100...999)
            operation = .multiplication
            secondOperation = .addition
            let multiplicationResult = firstNumber * secondNumber
            correctAnswer = multiplicationResult + thirdNumber!
        }
    }

    func isCorrect(_ answer: Int) -> Bool {
        answer == correctAnswer
    }
}

// MARK: - Typing Challenge

struct TypingChallenge: Challenge {
    let targetText: String
    let type: ChallengeType = .typing

    var questionText: String {
        targetText
    }

    private static let prompts = [
        "I'll use this on purpose, not by reflex.",
        "A few minutes here is a choice I'm making.",
        "I decide how this moment is spent.",
        "This is intentional time, not lost time.",
        "I'm here because I chose to be.",
    ]

    init() {
        self.targetText = TypingChallenge.prompts.randomElement() ?? TypingChallenge.prompts[0]
    }

    func isCorrect(_ typedText: String) -> Bool {
        typedText == targetText
    }

    func firstErrorIndex(in typedText: String) -> Int? {
        for (index, char) in typedText.enumerated() {
            let targetIndex = targetText.index(targetText.startIndex, offsetBy: index)
            if char != targetText[targetIndex] {
                return index
            }
        }
        return nil
    }
}

// MARK: - Memory Challenge

struct MemoryChallenge: Challenge {
    let litTiles: [Int]
    let gridSize: Int = 16
    let columns: Int = 4
    let litCount: Int = 4
    let type: ChallengeType = .memory

    var questionText: String {
        "Memorize the lit tiles"
    }

    init() {
        // Generate random lit tiles
        var indices = Array(0..<gridSize)
        indices.shuffle()
        self.litTiles = Array(indices.prefix(litCount)).sorted()
    }

    func isCorrect(_ selectedTiles: [Int]) -> Bool {
        selectedTiles.count == litCount && Set(selectedTiles) == Set(litTiles)
    }
}
