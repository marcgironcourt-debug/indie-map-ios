import SwiftUI

struct ContentView: View {
    var body: some View {
        WebView(urlString: "http://192.168.2.41:3010/fr")
            .ignoresSafeArea()
    }
}
