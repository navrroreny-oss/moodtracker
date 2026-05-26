import Foundation
import SwiftData

@Model
final class MoodEntry {
    var date: Date
    var moodRaw: Int
    var note: String

    init(date: Date, mood: MoodType, note: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.moodRaw = mood.rawValue
        self.note = note
    }

    var mood: MoodType {
        get { MoodType(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }
}
