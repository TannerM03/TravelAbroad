//
//  OpenAIManager.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/20/25.
//

import Foundation
import OpenAI

class OpenAIService {
    private let openAI: OpenAI

    init(apiKey: String) {
        openAI = OpenAI(apiToken: apiKey)
    }

    func generateSummary(for comments: [Comment], recommendationName: String) async throws -> String {
        let commentTexts: [String] = comments.compactMap { comment in
            guard let text = comment.comment, !text.isEmpty else { return nil }
            let rating = comment.rating
            return "Rating: \(rating)/5: \(text)"
        }

        guard !commentTexts.isEmpty else {
            return "No reviews available yet for \(recommendationName)"
        }

        let prompt = createPrompt(comments: commentTexts, recommendationName: recommendationName)
        let query = ChatQuery(
            messages: [
                .init(role: .system, content: "You are a travel expert assistant that creates concise, informative summaries of student travel reviews")!,
                .init(role: .user, content: prompt)!,
            ],
            model: .gpt4_o_mini
        )

        let result = try await openAI.chats(query: query)

        guard let summary = result.choices.first?.message.content else {
            throw SummaryError.noResponse
        }

        print(summary)

        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createPrompt(comments: [String], recommendationName: String) -> String {
        let commentsText = comments.joined(separator: "\n")

        return """
        Summarize these reviews for "\(recommendationName)" in 1-2 casual sentences:

        \(commentsText)

        What should students know? Talk like you're giving advice to a friend.
        """
    }

    enum SummaryError: Error {
        case noResponse
        case invalidComments

        var localizedDescription: String {
            switch self {
            case .noResponse:
                return "Failed to generate summary"
            case .invalidComments:
                return "No valid comments to summarize"
            }
        }
    }
}
