import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.06, green: 0.06, blue: 0.08), location: 0.0),
                    .init(color: Color(red: 0.10, green: 0.08, blue: 0.06), location: 0.55),
                    .init(color: Color(red: 0.05, green: 0.05, blue: 0.06), location: 1.0),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            #if DEBUG
            WebView(urlString: "http://localhost:3010/fr")
                .ignoresSafeArea()
            #else
            WebView(urlString: "https://indie-map.vercel.app/fr")
                .ignoresSafeArea()
            #endif
}
    }
}
