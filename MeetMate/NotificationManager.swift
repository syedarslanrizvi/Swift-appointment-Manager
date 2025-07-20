import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    var userNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()

    func requestAuthorization() {
        userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    func scheduleNotification(for meeting: MeetingEntity) {
        guard meeting.reminderSet, let reminderTime = meeting.reminderTime else { return }

        let content = UNMutableNotificationContent()
        content.title = meeting.title ?? "Meeting Reminder"
        content.subtitle = meeting.location ?? ""
        content.sound = UNNotificationSound.default

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime), repeats: false)

        let request = UNNotificationRequest(identifier: meeting.id?.uuidString ?? UUID().uuidString, content: content, trigger: trigger)

        userNotificationCenter.add(request)
    }

    func cancelNotification(for meeting: MeetingEntity) {
        guard let id = meeting.id?.uuidString else { return }
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
