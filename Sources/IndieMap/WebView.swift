import SwiftUI
import WebKit
import UIKit
import CoreLocation

final class GeoPermission: NSObject, CLLocationManagerDelegate {
    static let shared = GeoPermission()
    private let manager = CLLocationManager()
    private var didRequest = false

    private override init() {
        super.init()
        manager.delegate = self
    }

    func ensureAuthorized() {
        if didRequest { return }
        didRequest = true
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}


struct WebView: UIViewRepresentable {
    let urlString: String

    final class Coordinator: NSObject, WKUIDelegate {
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            guard let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
                completionHandler()
                return
            }

            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            root.present(alert, animated: true, completion: nil)
        }

        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestGeolocationPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        GeoPermission.shared.ensureAuthorized()
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)

        webView.uiDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear

        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)
        }

guard let url = URL(string: urlString) else { return webView }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
