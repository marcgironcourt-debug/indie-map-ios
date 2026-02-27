import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        if uiView.url == nil {
            uiView.load(URLRequest(url: url))
        }
    }
}
