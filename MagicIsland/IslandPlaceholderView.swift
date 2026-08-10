import SwiftUI

struct IslandPlaceholderView: View {
    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.black.opacity(0.92))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.22), radius: 18, y: 8)

            HStack(spacing: 8) {
                Circle()
                    .fill(Color(red: 0.39, green: 0.95, blue: 0.73))
                    .frame(width: 7, height: 7)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(.white.opacity(0.34))
                    .frame(width: 54, height: 6)
            }
        }
        .frame(width: IslandWindowController.placeholderSize.width,
               height: IslandWindowController.placeholderSize.height)
        .accessibilityLabel("Magic Island placeholder")
    }
}
