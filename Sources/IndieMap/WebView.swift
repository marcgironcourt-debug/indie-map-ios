import SwiftUI
import WebKit
import UIKit

struct WebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)

        webView.scrollView.contentInsetAdjustmentBehavior = .never

        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)
        webView.scrollView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)

        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        if uiView.url == nil {
            uiView.load(URLRequest(url: url))
        }
    }
}
