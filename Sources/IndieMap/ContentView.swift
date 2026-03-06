import SwiftUI

struct ContentView: View {
  @AppStorage("im_locale") private var locale = ""

  private var baseURL: String {
    return "https://indie-map.vercel.app"
  }

  private var initialURL: String {
    let l = (locale == "en" || locale == "fr") ? locale : "fr"
    return "\(baseURL)/\(l)"
  }

  var body: some View {
    ZStack {
      Color(red: 111/255, green: 101/255, blue: 40/255)
        .ignoresSafeArea()

      if locale == "en" || locale == "fr" {
        WebView(urlString: initialURL)
          .ignoresSafeArea()
      } else {
        VStack(spacing: 14) {
          Spacer()

          Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)

          Text("Indie Map")
            .font(.system(size: 52, weight: .semibold))
            .foregroundColor(.white)

          ZStack {
            Text("Back To Local")
              .font(.system(size: 20, weight: .regular))
              .italic()
              .kerning(2.6)
              .foregroundColor(.white)
              .offset(x: -0.8, y: -0.8)

            Text("Back To Local")
              .font(.system(size: 20, weight: .regular))
              .italic()
              .kerning(2.6)
              .foregroundColor(.white)
              .offset(x: 0.8, y: -0.8)

            Text("Back To Local")
              .font(.system(size: 20, weight: .regular))
              .italic()
              .kerning(2.6)
              .foregroundColor(.white)
              .offset(x: -0.8, y: 0.8)

            Text("Back To Local")
              .font(.system(size: 20, weight: .regular))
              .italic()
              .kerning(2.6)
              .foregroundColor(.white)
              .offset(x: 0.8, y: 0.8)

            Text("Back To Local")
              .font(.system(size: 20, weight: .regular))
              .italic()
              .kerning(2.6)
              .foregroundColor(Color(red: 92/255, green: 110/255, blue: 59/255))
          }
            .rotationEffect(.degrees(-2))

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
