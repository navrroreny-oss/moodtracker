import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \MoodEntry.date) private var entries: [MoodEntry]

    @AppStorage("emoji_0") private var emoji0 = "😊"
    @AppStorage("emoji_1") private var emoji1 = "🙂"
    @AppStorage("emoji_2") private var emoji2 = "😐"
    @AppStorage("emoji_3") private var emoji3 = "🙁"
    @AppStorage("emoji_4") private var emoji4 = "😞"

    @State private var displayedMonth = Date()
    @State private var selectedEntry: MoodEntry?

    private var cal: Calendar { .current }

    private var customEmojis: [String] {
        [emoji0, emoji1, emoji2, emoji3, emoji4]
    }

    private var daysInMonth: [Date?] {
        guard
            let monthRange = cal.range(of: .day, in: .month, for: displayedMonth),
            let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstDay)
        let offset = (firstWeekday - cal.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in monthRange {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private var weekdaySymbols: [String] {
        let symbols = cal.shortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private func entry(for date: Date) -> MoodEntry? {
        entries.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader

                HStack {
                    ForEach(weekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            CalendarDayCell(
                                date: date,
                                entry: entry(for: date),
                                customEmojis: customEmojis
                            )
                            .onTapGesture {
                                if let e = entry(for: date) {
                                    selectedEntry = e
                                }
                            }
                        } else {
                            Color.clear.frame(height: 48)
                        }
                    }
                }
                .padding(.horizontal, 12)

                Spacer()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        withAnimation { displayedMonth = Date() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.appGreen)
                }
            }
            .sheet(item: $selectedEntry) { entry in
                EntryDetailSheet(entry: entry, customEmojis: customEmojis)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(Color.appGreen)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation {
                    displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(Color.appGreen)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let entry: MoodEntry?
    let customEmojis: [String]

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var dayNumber: Int { Calendar.current.component(.day, from: date) }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 40, height: 40)

                if let entry = entry {
                    Text(customEmojis[entry.mood.rawValue])
                        .font(.system(size: 22))
                } else {
                    Text("\(dayNumber)")
                        .font(isToday ? .system(size: 14, weight: .bold) : .system(size: 14))
                        .foregroundStyle(isToday ? Color.appGreen : .secondary)
                }
            }
            .overlay(
                Circle()
                    .stroke(isToday ? (entry?.mood.color ?? Color.appGreen) : Color.clear, lineWidth: 2)
            )
        }
        .frame(height: 48)
    }

    private var circleFill: Color {
        if let entry = entry {
            return entry.mood.color.opacity(0.18)
        }
        return isToday ? Color.appGreen.opacity(0.12) : Color.clear
    }
}

struct EntryDetailSheet: View {
    let entry: MoodEntry
    let customEmojis: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text(customEmojis[entry.mood.rawValue])
                            .font(.system(size: 72))
                        Text(entry.mood.label)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(entry.mood.color)
                        Text(entry.date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(entry.mood.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    if !entry.note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Note", systemImage: "note.text")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(entry.note)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle(entry.date.formatted(.dateTime.month(.abbreviated).day().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.appGreen)
                }
            }
        }
    }
}
