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

    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {

        private func isInternal(_ url: URL, webView: WKWebView) -> Bool {
            guard let h = url.host?.lowercased(), !h.isEmpty else { return false }
            if h == "indie-map.vercel.app" { return true }
            if let cur = webView.url?.host?.lowercased(), cur == h { return true }
            return false
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                if url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https" {
                    if isInternal(url, webView: webView) {
                        webView.load(URLRequest(url: url))
                    } else {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
            return nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler:  (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
            let scheme = (url.scheme ?? "").lowercased()

            if scheme == "mailto" || scheme == "tel" {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }

            if (scheme == "http" || scheme == "https") && navigationAction.navigationType == .linkActivated {
                if isInternal(url, webView: webView) {
                    decisionHandler(.allow)
                } else {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                }
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WKWebView didFinish:", webView.url?.absoluteString ?? "<nil>")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WKWebView didFailProvisionalNavigation:", error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WKWebView didFail:", error.localizedDescription)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("WKWebView webContentProcessDidTerminate")
        }


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
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear


guard let url = URL(string: urlString) else { return webView }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
