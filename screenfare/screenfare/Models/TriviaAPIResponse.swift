//
//  TriviaAPIResponse.swift
//  screenfare
//
//  Created by Claude Code
//

import Foundation
import UIKit

// MARK: - API Response Models

struct TriviaAPIResponse: Decodable {
    let responseCode: Int
    let results: [TriviaQuestion]

    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

struct TriviaQuestion: Decodable {
    let type: String
    let difficulty: String
    let category: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case type, difficulty, category, question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }

    /// Returns all answers shuffled with the index of the correct answer
    func shuffledAnswers() -> (answers: [String], correctIndex: Int) {
        var allAnswers = incorrectAnswers + [correctAnswer]

        // Shuffle while tracking correct answer position
        var correctIndex = allAnswers.count - 1
        for i in stride(from: allAnswers.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            if i == correctIndex {
                correctIndex = j
            } else if j == correctIndex {
                correctIndex = i
            }
            allAnswers.swapAt(i, j)
        }

        return (allAnswers, correctIndex)
    }
}

// MARK: - HTML Decoding Extension

extension String {
    /// Decodes HTML entities like &quot;, &#039;, &amp; to their actual characters
    func decodingHTMLEntities() -> String {
        guard let data = self.data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }

        return attributedString.string
    }
}
