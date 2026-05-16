import SwiftUI
import WebKit
import UIKit
import CoreLocation

final class NavigationChooserViewController: UITableViewController {
    private let actions: [(String, URL)]

    init(actions: [(String, URL)]) {
        self.actions = actions
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let isFr = (UserDefaults.standard.string(forKey: "im_locale") ?? "fr") == "fr"
        title = isFr ? "Itinéraire" : "Directions"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: isFr ? "Annuler" : "Cancel", style: .done, target: self, action: #selector(close))
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        actions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = actions[indexPath.row].0
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let u = actions[indexPath.row].1
        dismiss(animated: true) {
            UIApplication.shared.open(u, options: [:], completionHandler: nil)
        }
    }
}


final class GeoPermission: NSObject, CLLocationManagerDelegate {
    static let shared = GeoPermission()
    let manager = CLLocationManager()
    private weak var webView: WKWebView?
    private var didRequest = false
    private var didSendInitialLocation = false

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func attach(webView: WKWebView) {
        self.webView = webView
        self.didSendInitialLocation = false
    }

    func ensureAuthorized() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            requestNativeLocation()
            return
        }
        if didRequest { return }
        didRequest = true
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            requestNativeLocation()
        }
    }

    func requestNativeLocation() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let loc = self.manager.location {
                self.syncToWebView(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
            }
            self.manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        if didSendInitialLocation { return }
        didSendInitialLocation = true
        syncToWebView(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GeoPermission didFailWithError:", error.localizedDescription)
    }

    func syncToWebView(lat: Double, lng: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.webView else { return }
            let js = """
            (function(){
              try{
                window.__IM_NATIVE_LOCATION__ = { lat: \(lat), lng: \(lng), ts: Date.now() };
              }catch(e){}
              try{
                window.dispatchEvent(new CustomEvent("im:native-location", {
                  detail: { lat: \(lat), lng: \(lng) }
                }));
              }catch(e){}
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}


struct WebView: UIViewRepresentable {
    let urlString: String
    let onReady: () -> Void

    
final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
        let onReady: () -> Void

        init(onReady: @escaping () -> Void) {
            self.onReady = onReady
            super.init()
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "imlog" else { return }
            print("[IM_WEB]", String(describing: message.body))
        }

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

            let isFr = (UserDefaults.standard.string(forKey: "im_locale") ?? "fr") == "fr"
            var actions: [(String, URL)] = [(isFr ? "Plans" : "Maps", appleURL)]

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

            let vc = NavigationChooserViewController(actions: actions)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet
            if let sh = nav.sheetPresentationController {
                sh.detents = [.medium(), .large()]
                sh.prefersGrabberVisible = true
                sh.largestUndimmedDetentIdentifier = nil
            }
            root.present(nav, animated: true)
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
            GeoPermission.shared.ensureAuthorized()
            if let loc = GeoPermission.shared.manager.location {
                GeoPermission.shared.syncToWebView(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
            }
            PushTokenBridge.shared.consumePendingOpenUrlIfNeeded(currentUrl: webView.url?.absoluteString)
            DispatchQueue.main.async { [weak self] in
                self?.onReady()
            }
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
        Coordinator(onReady: onReady)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let js = """
(function(){
try{
if(window.__IM_LOG_BRIDGE__)return;
window.__IM_LOG_BRIDGE__=true;
function send(kind,args){
try{
var out=[];
for(var i=0;i<args.length;i++){
try{var v=args[i];out.push(typeof v==="string"?v:JSON.stringify(v));}
catch(e){out.push(String(args[i]));}
}
window.webkit.messageHandlers.imlog.postMessage("["+kind+"] "+out.join(" "));
}catch(e){}
}
var _log=console.log?console.log.bind(console):function(){};
var _warn=console.warn?console.warn.bind(console):function(){};
var _error=console.error?console.error.bind(console):function(){};
console.log=function(){send("log",arguments);_log.apply(console,arguments);};
console.warn=function(){send("warn",arguments);_warn.apply(console,arguments);};
console.error=function(){send("error",arguments);_error.apply(console,arguments);};
window.addEventListener("error",function(e){
try{send("window.error",[e.message,e.filename,e.lineno+":"+e.colno]);}catch(err){}
});
window.addEventListener("unhandledrejection",function(e){
try{send("unhandledrejection",[String(e.reason)]);}catch(err){}
});
}catch(e){}
})();
"""
        userContentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        userContentController.add(context.coordinator, name: "imlog")
        config.userContentController = userContentController
        let webView = WKWebView(frame: .zero, configuration: config)
        GeoPermission.shared.attach(webView: webView)
        PushTokenBridge.shared.attach(webView: webView)
        GeoPermission.shared.ensureAuthorized()

        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear


guard let url = URL(string: urlString) else { return webView }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        if uiView.url?.absoluteString != url.absoluteString {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            uiView.load(request)
        }
    }
}
