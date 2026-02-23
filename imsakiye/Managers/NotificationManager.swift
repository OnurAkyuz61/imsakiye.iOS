//
//  NotificationManager.swift
//  imsakiye
//
//  İftar bildirimleri: 1 saat, 30 dk, 10 dk, 5 dk kala ve iftar anında.
//

import Foundation
import Combine
import UserNotifications

/// İftar bildirim seçenekleri (Ayarlar'dan açılıp kapatılır).
enum IftarReminder: String, CaseIterable, Identifiable {
    case oneHour = "1 saat kala"
    case thirtyMin = "30 dakika kala"
    case tenMin = "10 dakika kala"
    case fiveMin = "5 dakika kala"
    case atIftar = "İftar vakti (okunduğunda)"

    var id: String { rawValue }

    /// Bildirim tetiklenme zamanı (iftar vaktinden önceki süre). nil = iftar anı.
    var minutesBeforeIftar: Int? {
        switch self {
        case .oneHour: return 60
        case .thirtyMin: return 30
        case .tenMin: return 10
        case .fiveMin: return 5
        case .atIftar: return nil
        }
    }

    /// Bildirim başlığı
    var notificationTitle: String {
        switch self {
        case .oneHour: return "İftara 1 saat kaldı"
        case .thirtyMin: return "İftara 30 dakika kaldı"
        case .tenMin: return "İftara 10 dakika kaldı"
        case .fiveMin: return "İftara 5 dakika kaldı"
        case .atIftar: return "İftar vakti"
        }
    }

    /// Bildirim gövdesi
    var notificationBody: String {
        switch self {
        case .oneHour: return "Sofraya hazırlanabilirsiniz. Hayırlı iftarlar."
        case .thirtyMin: return "Yaklaşık yarım saat kaldı. Afiyet olsun."
        case .tenMin: return "Çok az kaldı. İftarınız hayırlı olsun."
        case .fiveMin: return "Son 5 dakika. Hayırlı iftarlar."
        case .atIftar: return "İftar vakti geldi. Allah kabul etsin."
        }
    }

    var userDefaultsKey: String { "notifyIftar_\(rawValue.replacingOccurrences(of: " ", with: "_"))" }
}

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private static let iftarCategoryId = "iftar_reminders"

    private init() {}

    // MARK: - Ayarlar (UserDefaults)

    func isEnabled(_ reminder: IftarReminder) -> Bool {
        defaults.object(forKey: reminder.userDefaultsKey) as? Bool ?? (reminder == .atIftar)
    }

    func setEnabled(_ reminder: IftarReminder, _ enabled: Bool) {
        defaults.set(enabled, forKey: reminder.userDefaultsKey)
        objectWillChange.send()
    }

    // MARK: - İzin

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            return granted
        @unknown default:
            return false
        }
    }

    // MARK: - Zamanlama

    /// Bir sonraki iftar tarihine göre bildirimleri planla (vakitler güncellenince çağrılır).
    func scheduleIftarNotifications(nextIftarDate: Date) {
        Task {
            await removePendingIftarNotifications()
            let granted = await requestAuthorizationIfNeeded()
            guard granted else { return }

            for reminder in IftarReminder.allCases where isEnabled(reminder) {
                let triggerDate: Date
                if let minutes = reminder.minutesBeforeIftar {
                    triggerDate = nextIftarDate.addingTimeInterval(-Double(minutes) * 60)
                } else {
                    triggerDate = nextIftarDate
                }
                let now = Date()
                guard triggerDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = reminder.notificationTitle
                content.body = reminder.notificationBody
                content.sound = .default
                content.categoryIdentifier = Self.iftarCategoryId

                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "iftar_\(reminder.rawValue.replacingOccurrences(of: " ", with: "_"))",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    private func removePendingIftarNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.filter { $0.identifier.hasPrefix("iftar_") }.map(\.identifier)
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
