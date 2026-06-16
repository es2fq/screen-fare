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

    /// Numeric difficulty level (1-5) for challenge gates
    var numericLevel: Int {
        switch self {
        case .veryEasy: return 1
        case .easy: return 2
        case .medium: return 3
        case .hard: return 4
        case .veryHard: return 5
        }
    }
}

enum TypingDifficulty: String, CaseIterable {
    case shortest = "Shortest"
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
    case longest = "Longest"
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

    // Convenience accessor for ticket design compatibility
    var question: String {
        questionText
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
    let difficulty: TypingDifficulty
    let type: ChallengeType = .typing

    var questionText: String {
        targetText
    }

    // Convenience accessor for ticket design compatibility
    var text: String {
        targetText
    }

    private static let promptsByDifficulty: [TypingDifficulty: [String]] = [
        .shortest: [
            "Action is the foundational key to success.",
            "Done is better than perfect.",
            "Focus on being productive instead of busy.",
            "The secret of getting ahead is getting started.",
            "Small progress is still progress.",
            "You don't have to be great to start.",
            "The best time to start was yesterday.",
            "Discipline is choosing what you want most.",
            "Success is the sum of small efforts.",
            "Make each day your masterpiece.",
        ],
        .short: [
            "The way to get started is to quit talking and begin doing.",
            "Don't watch the clock; do what it does and keep going.",
            "Productivity is never an accident; it is always the result of commitment.",
            "You can't use up creativity; the more you use, the more you have.",
            "The only way to do great work is to love what you do.",
            "Either you run the day or the day runs you.",
            "Amateurs sit and wait for inspiration; the rest of us just get up.",
            "If you spend too much time thinking, you'll never get anything done.",
            "It's not about having time; it's about making time.",
            "Concentrate all your thoughts upon the work at hand.",
        ],
        .medium: [
            "The difference between ordinary and extraordinary is that little extra effort you put in.",
            "Success doesn't come from what you do occasionally, but from what you do consistently.",
            "Your time is limited, so don't waste it living someone else's life or priorities.",
            "The future depends on what you do today, not what you plan to do tomorrow.",
            "Productivity isn't about being a workaholic; it's about prioritizing, planning, and protecting your time.",
            "Don't confuse activity with productivity; many people are busy but few are truly productive.",
            "The key is not to prioritize your schedule but to schedule your priorities first.",
            "Efficiency is doing things right; effectiveness is doing the right things at the right time.",
            "You will never find time for anything; if you want time, you must make it.",
            "Work smarter, not harder, and always measure your results to improve continuously.",
        ],
        .long: [
            "The most important thing in life is to stop saying I wish and start saying I will, then take action immediately.",
            "Until we can manage time, we can manage nothing else; time is the scarcest resource we have.",
            "Your mind is for having ideas, not holding them; write everything down and free your brain for deep work.",
            "Time management is really life management, personal management, and self-management combined into purposeful action.",
            "Motivation is what gets you started, but habit is what keeps you going when motivation fades away.",
            "What you do today can improve all your tomorrows if you focus on progress over perfection.",
            "The bad news is time flies; the good news is you're the pilot and can choose your destination.",
            "Don't say you don't have enough time; you have exactly the same hours per day as everyone else.",
            "Stop waiting for perfect timing; the perfect time will never arrive, so start with what you have now.",
            "If you really want to do something, you'll find a way; if you don't, you'll find an excuse.",
        ],
        .longest: [
            "The most dangerous thing you can do is to take any one impulse of your own nature and set it up as the thing you ought to follow at all times, because it will eventually destroy you.",
            "I have been impressed with the urgency of doing. Knowing is not enough; we must apply. Being willing is not enough; we must do something concrete every single day toward our goals.",
            "You can do two things at once, but you can't focus effectively on two things at once. Multitasking is the enemy of deep work and meaningful progress in everything you truly care about.",
            "The really important kind of freedom involves attention, and awareness, and discipline, and effort, and being able truly to care about other people and to sacrifice for them, over and over, in myriad petty little ways, every single day.",
            "Until you value yourself, you won't value your time. Until you value your time, you will not do anything with it. Your time is your life, and your life is the sum of your days and hours.",
            "All we have to decide is what to do with the time that is given to us. You cannot change the past or control the future, but you can make the most of this present moment right now.",
            "In a world where everyone is overexposed, the coolest thing you can do is maintain your focus, guard your attention zealously, and work deeply on things that matter most to you and your personal mission.",
            "The ultimate productivity hack is saying no to things that don't align with your goals, values, and vision for your life. Every yes to something unimportant is a no to something that truly matters to your future.",
            "We are what we repeatedly do. Excellence, then, is not an act but a habit built through consistent daily actions. Your daily routines and systems determine your success far more than occasional bursts of motivation ever will.",
            "Most people overestimate what they can do in one year and underestimate what they can do in ten years. Focus on sustainable daily habits and compound growth rather than seeking overnight transformations that never last.",
        ]
    ]

    init(difficulty: TypingDifficulty = .medium) {
        self.difficulty = difficulty
        let prompts = TypingChallenge.promptsByDifficulty[difficulty] ?? TypingChallenge.promptsByDifficulty[.medium]!
        self.targetText = prompts.randomElement() ?? prompts[0]
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
    let litIndices: [Int]
    let gridSize: Int
    let columns: Int
    let litCount: Int
    let type: ChallengeType = .memory

    var questionText: String {
        "Memorize the lit tiles"
    }

    // Legacy accessor for backwards compatibility
    var litTiles: [Int] {
        litIndices
    }

    init(gridSize: Int = 4, litCount: Int = 4) {
        self.gridSize = gridSize * gridSize
        self.columns = gridSize
        self.litCount = litCount

        // Generate random lit tiles
        var indices = Array(0..<self.gridSize)
        indices.shuffle()
        self.litIndices = Array(indices.prefix(litCount)).sorted()
    }

    func isCorrect(_ selectedTiles: [Int]) -> Bool {
        selectedTiles.count == litCount && Set(selectedTiles) == Set(litIndices)
    }
}
