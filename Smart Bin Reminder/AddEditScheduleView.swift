import SwiftUI

// Predefined bin name suggestions
private let binNameSuggestions = ["General Waste", "Recycling", "Garden Waste", "Glass", "Paper", "Food Waste"]

// Palette of curated hex colors
private let paletteColors = [
    "1C1C1E", "34C759", "FF9500", "FF3B30",
    "007AFF", "5856D6", "FF2D55", "AF52DE",
    "AC8E68", "FFCC00", "00C7BE", "30B0C7"
]

// Available SF Symbol icons for bins
private let binIcons = [
    "trash",
    "arrow.3.trianglepath",
    "leaf",
    "wineglass",
    "doc",
    "bag",
    "shippingbox",
    "bolt",
    "flame",
    "drop"
]

struct AddEditScheduleView: View {
    @EnvironmentObject var store: BinStore
    @Environment(\.dismiss) private var dismiss

    // nil means "add new", non-nil means "edit existing"
    var schedule: BinSchedule?

    @State private var name: String = ""
    @State private var colorHex: String = "1C1C1E"
    @State private var icon: String = "trash"
    @State private var repeatInterval: RepeatInterval = .weekly
    @State private var nextCollection: Date = nextFriday()
    @State private var isActive: Bool = true
    @State private var alertDayBefore: Bool = true
    @State private var alertDayBeforeTime: Date = makeTime(hour: 20)
    @State private var alertSameDay: Bool = true
    @State private var alertSameDayTime: Date = makeTime(hour: 7)

    @State private var showDeleteConfirm = false
    @State private var showNameSuggestions = false

    var isEditing: Bool { schedule != nil }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            Form {
                binInfoSection
                scheduleSection
                activeSection
                alertsSection
                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(isEditing ? "Edit Bin Schedule" : "Add Bin Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Delete this bin schedule?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let s = schedule { store.delete(s) }
                    dismiss()
                }
            }
        }
        .onAppear { populate() }
    }

    // MARK: - Form Sections

    private var binInfoSection: some View {
        Section {
            // Name field with quick-select suggestions
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("e.g. General Waste", text: $name)
                        .multilineTextAlignment(.trailing)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(binNameSuggestions, id: \.self) { suggestion in
                            Button(action: { name = suggestion }) {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        name == suggestion
                                            ? Color.accentColor
                                            : Color(.systemGray5)
                                    )
                                    .foregroundColor(name == suggestion ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, 4)

            // Color picker
            HStack {
                Text("Colour")
                Spacer()
                ColorPaletteRow(selectedHex: $colorHex, colors: paletteColors)
            }

            // Icon picker
            HStack {
                Text("Icon")
                Spacer()
                IconSelectorRow(
                    selectedIcon: $icon,
                    icons: binIcons,
                    color: Color(hex: colorHex) ?? .black
                )
            }
        }
    }

    private var scheduleSection: some View {
        Section {
            Picker("Every", selection: $repeatInterval) {
                ForEach(RepeatInterval.allCases) { interval in
                    Text(interval.displayName).tag(interval)
                }
            }

            DatePicker(
                "Next Collection",
                selection: $nextCollection,
                displayedComponents: .date
            )
        } header: {
            Text("Schedule")
        } footer: {
            Text("On \(weekdayName(from: nextCollection)), \(repeatInterval.repeatLabel.lowercased())")
        }
    }

    private var activeSection: some View {
        Section {
            Toggle("Active", isOn: $isActive)
        } footer: {
            if !isActive {
                Text("Deactivate a schedule if it is not being collected at this time of year.")
            }
        }
    }

    private var alertsSection: some View {
        Section(header: Text("Alerts")) {
            HStack {
                Toggle("Day Before", isOn: $alertDayBefore)
                if alertDayBefore {
                    Spacer()
                    DatePicker("", selection: $alertDayBeforeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            HStack {
                Toggle("Same Day", isOn: $alertSameDay)
                if alertSameDay {
                    Spacer()
                    DatePicker("", selection: $alertSameDayTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive, action: { showDeleteConfirm = true }) {
                HStack {
                    Spacer()
                    Text("Delete Bin Schedule")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Logic

    private func populate() {
        guard let s = schedule else { return }
        name = s.name
        colorHex = s.colorHex
        icon = s.icon
        repeatInterval = s.repeatInterval
        nextCollection = s.nextCollectionFromToday ?? s.nextCollection
        isActive = s.isActive
        alertDayBefore = s.alertDayBefore
        alertDayBeforeTime = makeTime(hour: s.alertDayBeforeHour, minute: s.alertDayBeforeMinute)
        alertSameDay = s.alertSameDay
        alertSameDayTime = makeTime(hour: s.alertSameDayHour, minute: s.alertSameDayMinute)
    }

    private func save() {
        let cal = Calendar.current
        let updated = BinSchedule(
            id: schedule?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            colorHex: colorHex,
            icon: icon,
            repeatInterval: repeatInterval,
            nextCollection: nextCollection,
            isActive: isActive,
            alertDayBefore: alertDayBefore,
            alertDayBeforeHour: cal.component(.hour, from: alertDayBeforeTime),
            alertDayBeforeMinute: cal.component(.minute, from: alertDayBeforeTime),
            alertSameDay: alertSameDay,
            alertSameDayHour: cal.component(.hour, from: alertSameDayTime),
            alertSameDayMinute: cal.component(.minute, from: alertSameDayTime)
        )
        isEditing ? store.update(updated) : store.add(updated)
        dismiss()
    }

    private func weekdayName(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE"
        return fmt.string(from: date)
    }
}

// MARK: - Colour Palette Row

struct ColorPaletteRow: View {
    @Binding var selectedHex: String
    let colors: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(colors, id: \.self) { hex in
                    let isSelected = selectedHex == hex
                    Circle()
                        .fill(Color(hex: hex) ?? .black)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.25), lineWidth: isSelected ? 3 : 0)
                                .padding(-3)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(isSelected ? 1 : 0)
                        )
                        .onTapGesture { selectedHex = hex }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Icon Selector Row

struct IconSelectorRow: View {
    @Binding var selectedIcon: String
    let icons: [String]
    let color: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(icons, id: \.self) { iconName in
                    let isSelected = selectedIcon == iconName
                    Circle()
                        .fill(isSelected ? color : Color(.systemGray5))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: iconName)
                                .font(.system(size: 16))
                                .foregroundColor(isSelected ? .white : .primary)
                        )
                        .onTapGesture { selectedIcon = iconName }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Helpers

private func makeTime(hour: Int, minute: Int = 0) -> Date {
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    comps.hour = hour
    comps.minute = minute
    return Calendar.current.date(from: comps) ?? Date()
}

private func nextFriday() -> Date {
    let calendar = Calendar.current
    var comps = DateComponents()
    comps.weekday = 6 // Friday
    return calendar.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime) ?? Date()
}
