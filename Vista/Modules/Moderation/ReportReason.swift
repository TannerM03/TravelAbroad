//
//  ReportReason.swift
//  Vista
//
//  Enum for content report reasons
//

import Foundation

enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "Spam"
    case harassment = "Harassment"
    case inappropriate = "Inappropriate Content"
    case hateSpeech = "Hate Speech"
    case violence = "Violence"
    case other = "Other"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .spam:
            return "Unwanted or repeated content"
        case .harassment:
            return "Bullying or threatening behavior"
        case .inappropriate:
            return "Sexually explicit or offensive content"
        case .hateSpeech:
            return "Content promoting hate or discrimination"
        case .violence:
            return "Content promoting or depicting violence"
        case .other:
            return "Other violation of Terms of Service"
        }
    }
}
