import SwiftUI

struct NotificationSettingsBanner: View {
    let onClose: () -> Void

    var body: some View {
        Button {
            NotificationBannerManager.shared.markShown()
            NotificationPermission.shared.openSettings()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 111/255, green: 101/255, blue: 40/255))
                        .frame(width: 44, height: 44)

                    Image(systemName: "bell.badge")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Activer les notifications")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text("Reste informé des mises à jour et découvre les derniers lieux ajoutés.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.82))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.82))
            )
            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        Button {
                            NotificationBannerManager.shared.markShown()
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.82))
                                .frame(width: 28, height: 28)
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                        Spacer()
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}
