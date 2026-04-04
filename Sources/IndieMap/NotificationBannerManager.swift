import Foundation

final class NotificationBannerManager {
    static let shared = NotificationBannerManager()

    private let key = "im_last_notif_banner"

    func shouldShowBanner() -> Bool {
        let last = UserDefaults.standard.double(forKey: key)
        if last == 0 { return true }

        let now = Date().timeIntervalSince1970
        let sevenDays: Double = 7 * 24 * 60 * 60

        return (now - last) > sevenDays
    }

    func markShown() {
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: key)
    }
}
