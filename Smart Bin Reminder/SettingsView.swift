import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var store: BinStore
    @AppStorage("appColorScheme") private var colorSchemePreference: String = "system"
    @State private var showDeleteAllConfirm = false
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    @State private var rescheduled = false

    var body: some View {
        NavigationView {
            Form {
                appearanceSection
                notificationsSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear { refreshStatus() }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog(
                "Delete all bin schedules?",
                isPresented: $showDeleteAllConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    for s in store.schedules { store.delete(s) }
                }
            }
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Picker("Theme", selection: $colorSchemePreference) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
        }
    }

    private var notificationsSection: some View {
        Section(header: Text("Notifications")) {
            HStack {
                Text("Status")
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: requestPermission) {
                HStack {
                    Text("Request Permission")
                    Spacer()
                    if authorizationStatus == .authorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .disabled(authorizationStatus == .denied)

            Button(action: rescheduleAll) {
                HStack {
                    Text("Reschedule All Reminders")
                    Spacer()
                    if rescheduled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .disabled(authorizationStatus != .authorized || store.schedules.isEmpty)

            if authorizationStatus == .denied {
                Text("Notifications are blocked. Enable them in Settings > Smart Bin Reminder.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var dataSection: some View {
        Section(header: Text("Data")) {
            HStack {
                Text("Schedules")
                Spacer()
                Text("\(store.schedules.count)")
                    .foregroundColor(.secondary)
            }
            Button(role: .destructive, action: { showDeleteAllConfirm = true }) {
                Text("Delete All Schedules")
            }
            .disabled(store.schedules.isEmpty)
        }
    }

    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func requestPermission() {
        switch authorizationStatus {
        case .authorized:
            present(title: "Already Allowed", message: "Notifications are already enabled for this app.")
        case .denied:
            present(title: "Notifications Blocked", message: "Open Settings > Smart Bin Reminder > Notifications to re-enable.")
        case .notDetermined:
            store.requestNotificationPermission()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { refreshStatus() }
        default:
            store.requestNotificationPermission()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { refreshStatus() }
        }
    }

    private func rescheduleAll() {
        guard authorizationStatus == .authorized else {
            present(title: "Notifications Disabled", message: "Grant notification permission first.")
            return
        }
        store.rescheduleAllNotifications()
        rescheduled = true
        present(
            title: "Reminders Rescheduled",
            message: "All upcoming bin reminders have been refreshed."
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { rescheduled = false }
    }

    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                authorizationStatus = settings.authorizationStatus
            }
        }
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

    // MARK: - Computed

    private var statusLabel: String {
        switch authorizationStatus {
        case .authorized:      return "Allowed"
        case .denied:          return "Denied"
        case .notDetermined:   return "Not Set"
        case .provisional:     return "Provisional"
        default:               return "Unknown"
        }
    }

    private var statusColor: Color {
        switch authorizationStatus {
        case .authorized:    return .green
        case .denied:        return .red
        default:             return .orange
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
