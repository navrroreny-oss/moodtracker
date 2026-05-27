import SwiftUI
import Foundation

enum RepeatInterval: Int, Codable, CaseIterable, Identifiable {
    case weekly = 1
    case everyTwoWeeks = 2
    case everyThreeWeeks = 3
    case everyFourWeeks = 4
    case everyFiveWeeks = 5
    case everySixWeeks = 6
    case everySevenWeeks = 7
    case everyEightWeeks = 8

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .weekly:          return "Week"
        case .everyTwoWeeks:   return "Two Weeks"
        case .everyThreeWeeks: return "Three Weeks"
        case .everyFourWeeks:  return "Four Weeks"
        case .everyFiveWeeks:  return "Five Weeks"
        case .everySixWeeks:   return "Six Weeks"
        case .everySevenWeeks: return "Seven Weeks"
        case .everyEightWeeks: return "Eight Weeks"
        }
    }

    var repeatLabel: String {
        self == .weekly ? "Weekly" : "Every \(displayName)"
    }
}

struct BinSchedule: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var icon: String
    var repeatInterval: RepeatInterval
    var nextCollection: Date
    var isActive: Bool = true
    var alertDayBefore: Bool = true
    var alertDayBeforeHour: Int = 20
    var alertDayBeforeMinute: Int = 0
    var alertSameDay: Bool = true
    var alertSameDayHour: Int = 7
    var alertSameDayMinute: Int = 0

    var color: Color {
        Color(hex: colorHex) ?? .black
    }

    /// All upcoming collection dates starting from `startDate` (defaults to today).
    func upcomingDates(from startDate: Date = Date(), count: Int = 30) -> [Date] {
        guard isActive else { return [] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: startDate)
        var current = calendar.startOfDay(for: nextCollection)

        // Advance base date forward until it reaches today or later
        while current < today {
            guard let next = calendar.date(byAdding: .weekOfYear, value: repeatInterval.rawValue, to: current) else { break }
            current = next
        }

        var dates: [Date] = []
        for _ in 0..<count {
            dates.append(current)
            guard let next = calendar.date(byAdding: .weekOfYear, value: repeatInterval.rawValue, to: current) else { break }
            current = next
        }
        return dates
    }

    var nextCollectionFromToday: Date? {
        upcomingDates(count: 1).first
    }
}

// MARK: - Color Hex Helpers

extension Color {
    init?(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgb) else { return nil }
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
