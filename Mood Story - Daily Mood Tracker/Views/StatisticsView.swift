import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \MoodEntry.date) private var entries: [MoodEntry]

    @AppStorage("emoji_0") private var emoji0 = "😊"
    @AppStorage("emoji_1") private var emoji1 = "🙂"
    @AppStorage("emoji_2") private var emoji2 = "😐"
    @AppStorage("emoji_3") private var emoji3 = "🙁"
    @AppStorage("emoji_4") private var emoji4 = "😞"

    private var customEmojis: [String] { [emoji0, emoji1, emoji2, emoji3, emoji4] }

    private var streak: Int {
        let cal = Calendar.current
        let dates = entries.map { cal.startOfDay(for: $0.date) }.sorted(by: >)
        guard let mostRecent = dates.first else { return 0 }
        guard cal.isDateInToday(mostRecent) || cal.isDateInYesterday(mostRecent) else { return 0 }

        var count = 0
        var expected = mostRecent
        for date in dates {
            if cal.isDate(date, inSameDayAs: expected) {
                count += 1
                expected = cal.date(byAdding: .day, value: -1, to: expected) ?? expected
            } else {
                break
            }
        }
        return count
    }

    private var averageMood: Double? {
        guard !entries.isEmpty else { return nil }
        return entries.map { $0.mood.score }.reduce(0, +) / Double(entries.count)
    }

    private var moodDistribution: [(mood: MoodType, count: Int)] {
        MoodType.allCases.map { mood in
            (mood, entries.filter { $0.mood == mood }.count)
        }
    }

    private var last30Days: [MoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -29,
                     to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return entries.filter { $0.date >= cutoff }
    }

    private var positivePercent: Double {
        guard !entries.isEmpty else { return 0 }
        let n = entries.filter { $0.mood == .veryGood || $0.mood == .good }.count
        return Double(n) / Double(entries.count) * 100
    }

    private var negativePercent: Double {
        guard !entries.isEmpty else { return 0 }
        let n = entries.filter { $0.mood == .bad || $0.mood == .veryBad }.count
        return Double(n) / Double(entries.count) * 100
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryCards
                            monthlySummaryCard
                            distributionCard
                            timelineCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(Color(.systemGray4))
            Text("No data yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Start recording your mood daily\nto see your statistics here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Entries",
                value: "\(entries.count)",
                icon: "calendar.badge.checkmark",
                color: .blue
            )
            StatCard(
                title: "Streak",
                value: "\(streak)",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "Avg Mood",
                value: averageMood.map { String(format: "%.1f", $0) } ?? "—",
                icon: "face.smiling",
                color: .appGreen
            )
        }
    }

    private var monthlySummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Overall Summary")
                .font(.headline)

            HStack(spacing: 16) {
                SummaryBar(label: "Positive", percent: positivePercent, color: .appGreen)
                SummaryBar(label: "Negative", percent: negativePercent, color: Color(red: 0.94, green: 0.35, blue: 0.35))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mood Distribution")
                .font(.headline)

            Chart(moodDistribution, id: \.mood.rawValue) { item in
                BarMark(
                    x: .value("Mood", customEmojis[item.mood.rawValue]),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.mood.color)
                .cornerRadius(6)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mood Timeline (Last 30 Days)")
                .font(.headline)

            if last30Days.isEmpty {
                Text("No data in the last 30 days")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(last30Days) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Score", entry.mood.score)
                    )
                    .foregroundStyle(Color.appGreen)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Score", entry.mood.score)
                    )
                    .foregroundStyle(entry.mood.color)
                    .symbolSize(40)
                }
                .chartYScale(domain: 0.5...5.5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        if let score = value.as(Double.self) {
                            let mood = MoodType.allCases.first { $0.score == score }
                            AxisValueLabel {
                                Text(mood.map { customEmojis[$0.rawValue] } ?? "")
                                    .font(.caption)
                            }
                            AxisGridLine()
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SummaryBar: View {
    let label: String
    let percent: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(percent))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemFill))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(percent / 100, 1.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
    }
}
