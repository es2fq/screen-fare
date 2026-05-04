//
//  MathChallengeGenerator.swift
//  screenfare
//
//  Created by Erik Song on 5/3/26.
//

import Foundation

enum ChallengeDifficulty: String, CaseIterable {
    case veryEasy = "Very Easy"
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case veryHard = "Very Hard"

    var range: ClosedRange<Int> {
        switch self {
        case .veryEasy: return 1...10
        case .easy: return 1...20
        case .medium: return 10...50
        case .hard: return 20...100
        case .veryHard: return 50...200
        }
    }

    var allowsMultiplication: Bool {
        switch self {
        case .veryEasy: return false
        case .easy: return false
        case .medium, .hard, .veryHard: return true
        }
    }
}

enum MathOperation: String, CaseIterable {
    case addition = "+"
    case subtraction = "−"
    case multiplication = "×"

    func calculate(_ a: Int, _ b: Int) -> Int {
        switch self {
        case .addition: return a + b
        case .subtraction: return a - b
        case .multiplication: return a * b
        }
    }
}

struct MathChallenge {
    let firstNumber: Int
    let secondNumber: Int
    let operation: MathOperation
    let correctAnswer: Int

    var questionText: String {
        "\(firstNumber) \(operation.rawValue) \(secondNumber) = ?"
    }

    init(difficulty: ChallengeDifficulty = .medium) {
        let range = difficulty.range

        // Filter operations based on difficulty
        let availableOperations: [MathOperation]
        if difficulty.allowsMultiplication {
            availableOperations = MathOperation.allCases
        } else {
            availableOperations = [.addition, .subtraction]
        }

        let operation = availableOperations.randomElement()!

        switch operation {
        case .addition:
            firstNumber = Int.random(in: range)
            secondNumber = Int.random(in: range)
        case .subtraction:
            // Ensure positive result
            let a = Int.random(in: range)
            let b = Int.random(in: range.lowerBound...a)
            firstNumber = a
            secondNumber = b
        case .multiplication:
            // Use smaller numbers for multiplication
            let smallerRange = range.lowerBound...(range.upperBound / 3)
            firstNumber = Int.random(in: smallerRange)
            secondNumber = Int.random(in: 2...10)
        }

        self.operation = operation
        self.correctAnswer = operation.calculate(firstNumber, secondNumber)
    }

    func isCorrect(_ answer: Int) -> Bool {
        answer == correctAnswer
    }
}
