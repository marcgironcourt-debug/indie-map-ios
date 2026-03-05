import SwiftUI

struct ContentView: View {
  @AppStorage("im_locale") private var locale = ""

  private var baseURL: String {
    #if targetEnvironment(simulator)
    return "http://192.168.2.41:3010"
    #else
    return "https://indie-map.vercel.app"
    #endif
  }

  private var initialURL: String {
    let l = (locale == "en" || locale == "fr") ? locale : "fr"
    return "\(baseURL)/\(l)"
  }

  var body: some View {
    ZStack {
      Color(red: 0.4784313725, green: 0.4352941176, blue: 0.1647058824)
        .ignoresSafeArea()

      if locale == "en" || locale == "fr" {
        WebView(urlString: initialURL)
          .ignoresSafeArea()
      } else {
        VStack(spacing: 14) {
          Spacer()
          Text("Indie Map")
            .font(.system(size: 36, weight: .semibold))
            .foregroundColor(.white)

          Text("Back To Local")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(Color.white.opacity(0.8))

          Spacer()

          VStack(spacing: 12) {
            Button {
              locale = "fr"
            } label: {
              Text("Français")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.18))
                .foregroundColor(.white)
                .cornerRadius(16)
            }

            Button {
              locale = "en"
            } label: {
              Text("English")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.18))
                .foregroundColor(.white)
                .cornerRadius(16)
            }
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 34)
        }
      }
    }
  }
}
