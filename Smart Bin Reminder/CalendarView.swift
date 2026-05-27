import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: BinStore
    @State private var displayMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdaySymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    // All upcoming collection dates mapped to their bins
    var collectionMap: [Date: [BinSchedule]] {
        var map: [Date: [BinSchedule]] = [:]
        for schedule in store.schedules where schedule.isActive {
            for date in schedule.upcomingDates(count: 60) {
                let day = calendar.startOfDay(for: date)
                map[day, default: []].append(schedule)
            }
        }
        return map
    }

    // All day cells for the displayed month (nil = empty padding cell)
    var dayCells: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        var cells: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in range {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: startOfMonth))
        }
        return cells
    }

    // Collections occurring in the displayed month, sorted by date
    var collectionsThisMonth: [(date: Date, bins: [BinSchedule])] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        return collectionMap
            .filter { $0.key >= startOfMonth && $0.key < endOfMonth }
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, bins: $0.value.sorted { $0.name < $1.name }) }
    }

    var monthYearLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayMonth)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    monthNavigationHeader
                    weekdayRow
                    daysGrid
                    Divider().padding(.top, 8)
                    collectionsList
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Calendar")
        }
    }

    // MARK: - Subviews

    private var monthNavigationHeader: some View {
        HStack {
            Button(action: { shiftMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(10)
                    .contentShape(Rectangle())
            }
            Spacer()
            Text(monthYearLabel)
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
            Button(action: { shiftMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .padding(10)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private var daysGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(0..<dayCells.count, id: \.self) { idx in
                if let date = dayCells[idx] {
                    let dayKey = calendar.startOfDay(for: date)
                    CalendarDayCell(
                        date: date,
                        collections: collectionMap[dayKey] ?? []
                    )
                } else {
                    Color.clear.frame(height: 52)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var collectionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if collectionsThisMonth.isEmpty {
                Text("No collections this month")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(collectionsThisMonth, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(longDateString(group.date))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 6)

                        ForEach(group.bins) { bin in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(bin.color)
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Image(systemName: bin.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    )
                                Text(bin.name)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }

                        Divider()
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func shiftMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newDate
        }
    }

    private func longDateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: date)
    }
}

// MARK: - Day Cell

struct CalendarDayCell: View {
    let date: Date
    let collections: [BinSchedule]

    private let calendar = Calendar.current

    var isToday: Bool { calendar.isDateInToday(date) }
    var dayNumber: Int { calendar.component(.day, from: date) }

    var body: some View {
        VStack(spacing: 3) {
            Text("\(dayNumber)")
                .font(.system(size: 15, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(isToday ? Color.accentColor : Color.clear)
                .clipShape(Circle())

            // Dot row: one dot per bin (up to 3)
            HStack(spacing: 3) {
                ForEach(collections.prefix(3)) { bin in
                    Circle()
                        .fill(bin.color)
                        .frame(width: 6, height: 6)
                }
                if collections.count > 3 {
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 8)
        }
        .frame(height: 52)
    }
}
