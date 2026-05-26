import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.date, order: .reverse) private var entries: [MoodEntry]

    @AppStorage("emoji_0") private var emoji0 = "😊"
    @AppStorage("emoji_1") private var emoji1 = "🙂"
    @AppStorage("emoji_2") private var emoji2 = "😐"
    @AppStorage("emoji_3") private var emoji3 = "🙁"
    @AppStorage("emoji_4") private var emoji4 = "😞"

    @State private var selectedMood: MoodType?
    @State private var noteText = ""
    @State private var isEditing = false

    private var todayEntry: MoodEntry? {
        entries.first { Calendar.current.isDateInToday($0.date) }
    }

    private var customEmojis: [String] {
        [emoji0, emoji1, emoji2, emoji3, emoji4]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    dateHeader

                    if let entry = todayEntry, !isEditing {
                        savedView(entry: entry)
                    } else {
                        moodPicker
                        noteField
                        saveButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if let entry = todayEntry, !isEditing {
                selectedMood = entry.mood
                noteText = entry.note
            }
        }
    }

    private var dateHeader: some View {
        VStack(spacing: 4) {
            Text(Date(), format: .dateTime.weekday(.wide))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Date(), format: .dateTime.day().month(.wide).year())
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var moodPicker: some View {
        VStack(spacing: 16) {
            Text("How do you feel today?")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(MoodType.allCases, id: \.rawValue) { mood in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMood = mood
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(customEmojis[mood.rawValue])
                                .font(.system(size: 32))
                                .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: selectedMood)
                            Text(mood.label)
                                .font(.system(size: 9))
                                .foregroundStyle(selectedMood == mood ? mood.color : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedMood == mood ? mood.color.opacity(0.12) : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedMood == mood ? mood.color : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (optional)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Write something about your day...", text: $noteText, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var saveButton: some View {
        Button {
            saveEntry()
        } label: {
            Text(todayEntry != nil ? "Update" : "Save")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedMood != nil ? Color.appGreen : Color(.systemGray4))
                )
        }
        .disabled(selectedMood == nil)
        .animation(.default, value: selectedMood)
    }

    @ViewBuilder
    private func savedView(entry: MoodEntry) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(customEmojis[entry.mood.rawValue])
                    .font(.system(size: 80))
                Text(entry.mood.label)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.mood.color)
                Text("Recorded today")
                    .font(.caption)
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

            Button {
                selectedMood = entry.mood
                noteText = entry.note
                isEditing = true
            } label: {
                Label("Edit Today's Entry", systemImage: "pencil")
                    .font(.subheadline)
                    .foregroundStyle(Color.appGreen)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.appGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func saveEntry() {
        guard let mood = selectedMood else { return }

        if let existing = todayEntry {
            existing.mood = mood
            existing.note = noteText
        } else {
            let entry = MoodEntry(date: Date(), mood: mood, note: noteText)
            modelContext.insert(entry)
        }

        isEditing = false
        try? modelContext.save()
    }
}
