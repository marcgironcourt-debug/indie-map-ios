import SwiftUI

@main
struct IndieMapApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()

                ContentView()
            }
        }
    }
}
