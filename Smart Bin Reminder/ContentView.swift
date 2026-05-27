import SwiftUI

struct ContentView: View {
    @StateObject private var store = BinStore()
    @AppStorage("appColorScheme") private var colorSchemePreference: String = "system"

    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .environmentObject(store)
        .preferredColorScheme(colorScheme)
        .onAppear {
            store.requestNotificationPermission()
        }
    }
}

#Preview {
    ContentView()
}
