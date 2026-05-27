import Foundation
import UserNotifications
import SwiftUI

class BinStore: ObservableObject {
    @Published var schedules: [BinSchedule] = []

    private let storageKey = "binSchedules"

    init() {
        load()
    }

    // MARK: - CRUD

    func add(_ schedule: BinSchedule) {
        schedules.append(schedule)
        save()
        scheduleNotifications(for: schedule)
    }

    func update(_ schedule: BinSchedule) {
        guard let idx = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        cancelNotifications(for: schedules[idx])
        schedules[idx] = schedule
        save()
        scheduleNotifications(for: schedule)
    }

    func delete(_ schedule: BinSchedule) {
        cancelNotifications(for: schedule)
        schedules.removeAll { $0.id == schedule.id }
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(schedules) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([BinSchedule].self, from: data)
        else { return }
        schedules = decoded
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func rescheduleAllNotifications() {
        for schedule in schedules {
            cancelNotifications(for: schedule)
        }
        // Brief delay so cancellations process before re-adding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            for schedule in self.schedules {
                self.scheduleNotifications(for: schedule)
            }
        }
    }

    private func scheduleNotifications(for schedule: BinSchedule) {
        guard schedule.isActive else { return }
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        // Limit to next 5 dates to stay within iOS 64-notification cap
        let dates = schedule.upcomingDates(count: 5)

        for date in dates {
            if schedule.alertDayBefore {
                let dayBefore = calendar.date(byAdding: .day, value: -1, to: date)!
                var comps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
                comps.hour = schedule.alertDayBeforeHour
                comps.minute = schedule.alertDayBeforeMinute

                let content = UNMutableNotificationContent()
                content.title = "Bin Day Tomorrow"
                content.body = "Put out your \(schedule.name) bin tonight"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "\(schedule.id)-before-\(Int(calendar.startOfDay(for: date).timeIntervalSince1970))"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }

            if schedule.alertSameDay {
                var comps = calendar.dateComponents([.year, .month, .day], from: date)
                comps.hour = schedule.alertSameDayHour
                comps.minute = schedule.alertSameDayMinute

                let content = UNMutableNotificationContent()
                content.title = "Bin Day Today"
                content.body = "Don't forget to put out your \(schedule.name) bin"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "\(schedule.id)-same-\(Int(calendar.startOfDay(for: date).timeIntervalSince1970))"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    private func cancelNotifications(for schedule: BinSchedule) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(schedule.id.uuidString) }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
