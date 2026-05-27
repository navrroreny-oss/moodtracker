import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: BinStore
    @State private var showAdd = false

    // Groups upcoming collection dates with their bins, up to 20 future date-slots
    var groupedCollections: [(date: Date, bins: [BinSchedule])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var map: [Date: [BinSchedule]] = [:]

        for schedule in store.schedules where schedule.isActive {
            for date in schedule.upcomingDates(count: 15) {
                let day = calendar.startOfDay(for: date)
                map[day, default: []].append(schedule)
            }
        }

        return map.keys
            .filter { $0 >= today }
            .sorted()
            .prefix(20)
            .map { date in
                (date: date, bins: map[date]!.sorted { $0.name < $1.name })
            }
    }

    var nextCollection: (date: Date, bins: [BinSchedule])? {
        groupedCollections.first
    }

    var body: some View {
        NavigationView {
            Group {
                if store.schedules.isEmpty {
                    emptyStateView
                } else {
                    collectionListView
                }
            }
            .navigationTitle("Bin Reminder")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEditScheduleView()
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "trash.circle")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            VStack(spacing: 8) {
                Text("No Schedules Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Add your first bin collection schedule to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button(action: { showAdd = true }) {
                Label("Add Schedule", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    private var collectionListView: some View {
        List {
            // Next collection banner
            if let next = nextCollection {
                Section {
                    NextCollectionBanner(date: next.date, bins: next.bins)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            // Grouped schedule rows
            ForEach(groupedCollections, id: \.date) { group in
                Section(header: sectionHeader(for: group.date)) {
                    ForEach(group.bins) { bin in
                        BinRowView(schedule: bin)
                            .environmentObject(store)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func sectionHeader(for date: Date) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let daysUntil = calendar.dateComponents([.day], from: today, to: date).day ?? 0

        let label: String
        if date == today {
            label = "Today"
        } else if date == tomorrow {
            label = "Tomorrow"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEEE, MMMM d"
            label = fmt.string(from: date)
        }

        return HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            if daysUntil > 1 {
                Text("in \(daysUntil) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Next Collection Banner

struct NextCollectionBanner: View {
    let date: Date
    let bins: [BinSchedule]

    var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: today, to: date).day ?? 0
    }

    var countdownLabel: String {
        switch daysUntil {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(daysUntil) days"
        }
    }

    var dateLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Collection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(countdownLabel)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(dateLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: -8) {
                    ForEach(bins.prefix(4)) { bin in
                        Circle()
                            .fill(bin.color)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: bin.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Bin Row

struct BinRowView: View {
    @EnvironmentObject var store: BinStore
    let schedule: BinSchedule
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(schedule.color)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: schedule.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(schedule.repeatInterval.repeatLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 6)
                .fill(schedule.color.opacity(0.15))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: schedule.icon)
                        .font(.system(size: 13))
                        .foregroundColor(schedule.color)
                )
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { showEdit = true }
        .sheet(isPresented: $showEdit) {
            AddEditScheduleView(schedule: schedule)
                .environmentObject(store)
        }
    }
}
