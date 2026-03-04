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

        private func topController() -> UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        }

        private func isAppleMapsLink(_ url: URL) -> Bool {
            (url.host ?? "").lowercased() == "maps.apple.com"
        }

        private func parseAppleMapsDestination(_ url: URL) -> (lat: Double?, lng: Double?, query: String?) {
            guard let c = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return (nil, nil, nil) }
            let items = c.queryItems ?? []
            func get(_ name: String) -> String {
                for it in items {
                    if it.name.lowercased() == name.lowercased() { return (it.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
                }
                return ""
            }
            let daddr = get("daddr")
            let q = get("q")
            let query = get("query")
            let raw = !daddr.isEmpty ? daddr : (!q.isEmpty ? q : (!query.isEmpty ? query : ""))
            if raw.isEmpty { return (nil, nil, nil) }
            let parts = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2, let la = Double(parts[0]), let ln = Double(parts[1]) {
                return (la, ln, raw)
            }
            return (nil, nil, raw)
        }

        private func presentNavigationChooser(_ appleURL: URL) {
            guard let root = topController() else {
                UIApplication.shared.open(appleURL, options: [:], completionHandler: nil)
                return
            }

            let parsed = parseAppleMapsDestination(appleURL)
            let lat = parsed.lat
            let lng = parsed.lng
            let query = parsed.query

            var actions: [(String, URL)] = [("Plans", appleURL)]

            if let q = query, !q.isEmpty {
                if let u = URL(string: "comgooglemaps://?daddr=" + (q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")),
                   UIApplication.shared.canOpenURL(u) {
                    actions.append(("Google Maps", u))
                } else if let uw = URL(string: "https://www.google.com/maps/dir/?api=1&destination=" + (q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")) {
                    actions.append(("Google Maps", uw))
                }
            }

            if let la = lat, let ln = lng {
                let ll = "\(la),\(ln)"
                if let u = URL(string: "waze://?ll=" + (ll.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") + "&navigate=yes"),
                   UIApplication.shared.canOpenURL(u) {
                    actions.append(("Waze", u))
                } else if let uw = URL(string: "https://waze.com/ul?ll=" + (ll.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") + "&navigate=yes") {
                    actions.append(("Waze", uw))
                }
            } else if let q = query, !q.isEmpty {
                if let u = URL(string: "waze://?q=" + (q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") + "&navigate=yes"),
                   UIApplication.shared.canOpenURL(u) {
                    actions.append(("Waze", u))
                } else if let uw = URL(string: "https://waze.com/ul?q=" + (q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") + "&navigate=yes") {
                    actions.append(("Waze", uw))
                }
            }

            if actions.count == 1 {
                UIApplication.shared.open(appleURL, options: [:], completionHandler: nil)
                return
            }

            let sheet = UIAlertController(title: "Itinéraire", message: nil, preferredStyle: .actionSheet)
            for (t, u) in actions {
                sheet.addAction(UIAlertAction(title: t, style: .default) { _ in
                    UIApplication.shared.open(u, options: [:], completionHandler: nil)
                })
            }
            sheet.addAction(UIAlertAction(title: "Annuler", style: .cancel))

            if let pop = sheet.popoverPresentationController {
                pop.sourceView = root.view
                pop.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.maxY - 8, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }

            root.present(sheet, animated: true)
        }


        private func isInternal(_ url: URL, webView: WKWebView) -> Bool {
            guard let h = url.host?.lowercased(), !h.isEmpty else { return false }
            if h == "indie-map.vercel.app" { return true }
            if let cur = webView.url?.host?.lowercased(), cur == h { return true }
            return false
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                if url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https" {
                    if isAppleMapsLink(url) {
                        presentNavigationChooser(url)
                        return nil
                    }

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

            if (scheme == "http" || scheme == "https") && isAppleMapsLink(url) {
                presentNavigationChooser(url)
                decisionHandler(.cancel)
                return
            }

            if scheme == "mailto" || scheme == "tel" {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }

            if (scheme == "http" || scheme == "https") && navigationAction.navigationType == .linkActivated {
                if isAppleMapsLink(url) {
                    presentNavigationChooser(url)
                    decisionHandler(.cancel)
                    return
                }

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
