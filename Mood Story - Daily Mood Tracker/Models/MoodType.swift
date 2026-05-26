import SwiftUI

enum MoodType: Int, CaseIterable, Codable {
    case veryGood = 0
    case good = 1
    case neutral = 2
    case bad = 3
    case veryBad = 4

    var defaultEmoji: String {
        switch self {
        case .veryGood: return "😊"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .bad: return "🙁"
        case .veryBad: return "😞"
        }
    }

    var label: String {
        switch self {
        case .veryGood: return "Very Good"
        case .good: return "Good"
        case .neutral: return "Neutral"
        case .bad: return "Bad"
        case .veryBad: return "Very Bad"
        }
    }

    var color: Color {
        switch self {
        case .veryGood: return Color(red: 0.33, green: 0.69, blue: 0.31)
        case .good: return Color(red: 0.55, green: 0.76, blue: 0.29)
        case .neutral: return Color(red: 0.62, green: 0.62, blue: 0.62)
        case .bad: return Color(red: 0.98, green: 0.65, blue: 0.15)
        case .veryBad: return Color(red: 0.94, green: 0.35, blue: 0.35)
        }
    }

    var score: Double {
        switch self {
        case .veryGood: return 5.0
        case .good: return 4.0
        case .neutral: return 3.0
        case .bad: return 2.0
        case .veryBad: return 1.0
        }
    }
}

extension Color {
    static let appGreen = Color(red: 0.33, green: 0.69, blue: 0.31)
}
