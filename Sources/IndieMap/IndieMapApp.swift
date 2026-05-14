import SwiftUI
import UIKit
import UserNotifications

import WebKit

final class PushTokenBridge {
    static let shared = PushTokenBridge()

    private weak var webView: WKWebView?
    private var pendingToken: String?
    private var pendingUrl: String?

    func attach(webView: WKWebView) {
        self.webView = webView
        if let token = pendingToken {
            inject(token: token)
        }
        if let url = pendingUrl {
            injectOpenUrl(url)
        }
    }

    func update(token: String) {
        pendingToken = token
        UserDefaults.standard.set(token, forKey: "im_apns_token")
        inject(token: token)
    }

    func open(url: String) {
        pendingUrl = url
        injectOpenUrl(url)
    }

    private func inject(token: String) {
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.webView else { return }
            let escaped = token.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            let js = """
            (function(){
              try{
                window.__IM_PENDING_PUSH_TOKEN__ = "\(escaped)";
                if (typeof window.__IM_REGISTER_PUSH_TOKEN__ === "function") {
                  window.__IM_REGISTER_PUSH_TOKEN__("\(escaped)");
                }
              }catch(e){}
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func injectOpenUrl(_ url: String) {
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.webView else { return }
            let escaped = url.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            let js = "try{ window.location.href = \"\(escaped)\"; }catch(e){}"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("APNS device token:", token)
        PushTokenBridge.shared.update(token: token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNS registration failed:", error.localizedDescription)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let rawUrl = userInfo["url"] as? String
        let url = rawUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url, !url.isEmpty {
            PushTokenBridge.shared.open(url: url)
        }
    }
}

@main
struct IndieMapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
