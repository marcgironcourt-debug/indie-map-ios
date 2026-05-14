import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationPermission: NSObject, ObservableObject {
    static let shared = NotificationPermission()

    enum Status: String {
        case unknown
        case notDetermined
        case denied
        case authorized
        case provisional
        case ephemeral
    }

    @Published var status: Status = .unknown

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            status = .notDetermined
        case .denied:
            status = .denied
        case .authorized:
            status = .authorized
            UIApplication.shared.registerForRemoteNotifications()
        case .provisional:
            status = .provisional
            UIApplication.shared.registerForRemoteNotifications()
        case .ephemeral:
            status = .ephemeral
            UIApplication.shared.registerForRemoteNotifications()
        @unknown default:
            status = .unknown
        }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshStatus()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            await refreshStatus()
            return false
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
