import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [MoodEntry]

    @AppStorage("colorSchemeRaw") private var colorSchemeRaw = 0
    @AppStorage("emoji_0") private var emoji0 = "😊"
    @AppStorage("emoji_1") private var emoji1 = "🙂"
    @AppStorage("emoji_2") private var emoji2 = "😐"
    @AppStorage("emoji_3") private var emoji3 = "🙁"
    @AppStorage("emoji_4") private var emoji4 = "😞"

    @State private var showDeleteConfirmation = false
    @State private var editingEmojiIndex: Int?
    @State private var tempEmoji = ""

    private var customEmojis: [String] {
        [emoji0, emoji1, emoji2, emoji3, emoji4]
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Theme")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("Theme", selection: $colorSchemeRaw) {
                            Text("System").tag(0)
                            Text("Light").tag(1)
                            Text("Dark").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    ForEach(MoodType.allCases, id: \.rawValue) { mood in
                        HStack {
                            Text(mood.label)
                            Spacer()
                            Button {
                                tempEmoji = customEmojis[mood.rawValue]
                                editingEmojiIndex = mood.rawValue
                            } label: {
                                Text(customEmojis[mood.rawValue])
                                    .font(.title2)
                                    .padding(6)
                                    .background(mood.color.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Mood Emoji")
                } footer: {
                    Text("Tap an emoji to change it.")
                        .font(.caption)
                }

                Section("Data") {
                    HStack {
                        Text("Total entries")
                        Spacer()
                        Text("\(entries.count)")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                    .disabled(entries.isEmpty)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Change Emoji", isPresented: Binding(
                get: { editingEmojiIndex != nil },
                set: { if !$0 { editingEmojiIndex = nil } }
            )) {
                TextField("Paste emoji here", text: $tempEmoji)
                Button("Save") {
                    applyEmoji()
                }
                Button("Cancel", role: .cancel) {
                    editingEmojiIndex = nil
                }
            } message: {
                Text("Enter a new emoji for this mood")
            }
            .confirmationDialog(
                "Delete All Data",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(entries.count) mood entries. This cannot be undone.")
            }
        }
    }

    private func applyEmoji() {
        guard let index = editingEmojiIndex else { return }
        let value = String(tempEmoji.unicodeScalars.prefix(2).reduce("") { $0 + String($1) })
        guard !value.isEmpty else { editingEmojiIndex = nil; return }
        switch index {
        case 0: emoji0 = value
        case 1: emoji1 = value
        case 2: emoji2 = value
        case 3: emoji3 = value
        case 4: emoji4 = value
        default: break
        }
        editingEmojiIndex = nil
    }

    private func deleteAllData() {
        for entry in entries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}
