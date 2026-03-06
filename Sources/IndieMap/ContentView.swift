import SwiftUI

struct BrandSplashView: View {
  let showsLanguageButtons: Bool
  let onSelectFrench: () -> Void
  let onSelectEnglish: () -> Void

  var body: some View {
    ZStack {
      Color(red: 111/255, green: 101/255, blue: 40/255)
        .ignoresSafeArea()

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

        if showsLanguageButtons {
          VStack(spacing: 12) {
            Button(action: onSelectFrench) {
              Text("Français")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.18))
                .foregroundColor(.white)
                .cornerRadius(16)
            }

            Button(action: onSelectEnglish) {
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

struct ContentView: View {
  @AppStorage("im_locale") private var locale = ""
  @State private var webViewReady = false
  @State private var minimumSplashElapsed = false

  private var baseURL: String {
    return "https://indie-map.vercel.app"
  }

  private var initialURL: String {
    let l = (locale == "en" || locale == "fr") ? locale : "fr"
    return "\(baseURL)/\(l)"
  }

  private var hasLocale: Bool {
    locale == "en" || locale == "fr"
  }

  private var shouldShowSplashOverlay: Bool {
    if !hasLocale { return false }
    return !(webViewReady && minimumSplashElapsed)
  }

  private func startLaunchSequence() {
    webViewReady = false
    minimumSplashElapsed = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
      minimumSplashElapsed = true
    }
  }

  var body: some View {
    ZStack {
      if hasLocale {
        WebView(
          urlString: initialURL,
          onReady: {
            webViewReady = true
          }
        )
        .ignoresSafeArea()
      } else {
        BrandSplashView(
          showsLanguageButtons: true,
          onSelectFrench: { locale = "fr" },
          onSelectEnglish: { locale = "en" }
        )
      }

      if shouldShowSplashOverlay {
        BrandSplashView(
          showsLanguageButtons: false,
          onSelectFrench: {},
          onSelectEnglish: {}
        )
        .ignoresSafeArea()
      }
    }
    .onAppear {
      if hasLocale {
        startLaunchSequence()
      }
    }
    .onChange(of: locale) { _, newValue in
      if newValue == "en" || newValue == "fr" {
        startLaunchSequence()
      } else {
        webViewReady = false
        minimumSplashElapsed = false
      }
    }
  }
}
