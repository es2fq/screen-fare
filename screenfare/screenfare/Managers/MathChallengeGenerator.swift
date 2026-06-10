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

struct MathChallenge {
    let firstNumber: Int
    let secondNumber: Int
    let thirdNumber: Int?
    let operation: MathOperation
    let secondOperation: MathOperation?
    let correctAnswer: Int

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
