import AppKit
import SwiftUI

struct IslandPlaceholderView: View {
    let size: CGSize
    let presentation: IslandPresentation
    let currentActivity: CurrentActivity?
    let onMediaCommand: (MediaCommand) -> Void
    let onHomeSelection: (HomeDestination) -> Void

    init(
        size: CGSize = IslandWindowController.placeholderSize,
        presentation: IslandPresentation = .passive,
        currentActivity: CurrentActivity? = nil,
        onMediaCommand: @escaping (MediaCommand) -> Void = { _ in },
        onHomeSelection: @escaping (HomeDestination) -> Void = { _ in }
    ) {
        self.size = size
        self.presentation = presentation
        self.currentActivity = currentActivity
        self.onMediaCommand = onMediaCommand
        self.onHomeSelection = onHomeSelection
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.black.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.22), radius: 18, y: 8)

            content
        }
        .frame(width: size.width, height: size.height)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch presentation {
        case .passive, .collapsing:
            compactContent(isPeeking: false)
        case .peek:
            compactContent(isPeeking: true)
        case .expanded(let anchor):
            expandedContent(anchor: anchor)
        }
    }

    private var cornerRadius: CGFloat {
        switch presentation {
        case .expanded:
            return 22
        case .passive, .peek, .collapsing:
            return size.height / 2
        }
    }

    private var accessibilityLabel: String {
        switch presentation {
        case .passive:
            return "Magic Island passive"
        case .peek:
            return "Magic Island peek"
        case .expanded:
            return "Magic Island expanded"
        case .collapsing:
            return "Magic Island collapsing"
        }
    }

    private func compactContent(isPeeking: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(compactAccentColor)
                .frame(width: 7, height: 7)

            if let currentActivity {
                Text(compactTitle(for: currentActivity))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .frame(maxWidth: isPeeking ? 118 : 82, alignment: .leading)
            } else {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(.white.opacity(0.34))
                    .frame(width: isPeeking ? 84 : 54, height: 6)
            }
        }
        .padding(.horizontal, 12)
    }

    private func expandedContent(anchor: IslandExpansionAnchor) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Circle()
                    .fill(accentColor(for: anchor))
                    .frame(width: 9, height: 9)

                Text(title(for: anchor))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()
            }

            Text(subtitle(for: anchor))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)

            activityDetail(for: anchor)

            homeNavigation
        }
        .padding(22)
    }

    @ViewBuilder
    private func activityDetail(for anchor: IslandExpansionAnchor) -> some View {
        switch anchor {
        case .currentActivity(let activity):
            switch activity.presentation {
            case .generic:
                Spacer(minLength: 0)
            case .media(let media):
                mediaDetail(media)
            }
        case .idlePlaceholder:
            Spacer(minLength: 0)
        }
    }

    private func mediaDetail(_ media: MediaActivity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                artwork(for: media)

                VStack(alignment: .leading, spacing: 4) {
                    Text(media.appName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))

                    Text(media.playbackState == .playing ? "Playing" : "Paused")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()
            }

            HStack(spacing: 8) {
                transportButton(
                    "backward.fill",
                    isEnabled: media.supportedControls.contains(.previous),
                    command: .previous
                )
                transportButton(
                    media.playbackState == .playing ? "pause.fill" : "play.fill",
                    isEnabled: media.supportedControls.contains(.playPause),
                    command: .playPause
                )
                transportButton(
                    "forward.fill",
                    isEnabled: media.supportedControls.contains(.next),
                    command: .next
                )

                if media.supportedControls.contains(.seek) {
                    mediaProgress(media)
                }
            }
        }
    }

    private func artwork(for media: MediaActivity) -> some View {
        ZStack {
            if let image = image(from: media.artworkData) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.white.opacity(0.14))

                Image(systemName: "music.note")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func transportButton(
        _ systemName: String,
        isEnabled: Bool,
        command: MediaCommand
    ) -> some View {
        Button(action: { onMediaCommand(command) }) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(isEnabled ? 0.86 : 0.28))
                .frame(width: 30, height: 28)
        }
        .buttonStyle(.plain)
        .background(.white.opacity(isEnabled ? 0.14 : 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .disabled(!isEnabled)
    }

    private func mediaProgress(_ media: MediaActivity) -> some View {
        let fraction = progressFraction(for: media)

        return Button(action: {
            guard let duration = media.duration else {
                return
            }
            onMediaCommand(.seek(min(duration, (media.position ?? 0) + 15)))
        }) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))

                    Capsule()
                        .fill(Color(red: 0.39, green: 0.95, blue: 0.73))
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .frame(width: 96, height: 5)
        }
        .buttonStyle(.plain)
    }

    private var homeNavigation: some View {
        HStack(spacing: 8) {
            homeNavigationItem(.media, systemName: "music.note")
            homeNavigationItem(.fileShelf, systemName: "folder")
            homeNavigationItem(.clipboardHistory, systemName: "doc.on.clipboard")
            homeNavigationItem(.settings, systemName: "gearshape")
        }
    }

    private func homeNavigationItem(_ destination: HomeDestination, systemName: String) -> some View {
        Button(action: { onHomeSelection(destination) }) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.52))
                .frame(width: 26, height: 24)
        }
        .buttonStyle(.plain)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private func title(for anchor: IslandExpansionAnchor) -> String {
        switch anchor {
        case .currentActivity(let activity):
            return activity.title
        case .idlePlaceholder:
            return "Magic Island"
        }
    }

    private func subtitle(for anchor: IslandExpansionAnchor) -> String {
        switch anchor {
        case .currentActivity(let activity):
            return activity.subtitle
        case .idlePlaceholder:
            return "Idle"
        }
    }

    private func compactTitle(for activity: CurrentActivity) -> String {
        switch activity.presentation {
        case .generic:
            return activity.title
        case .media(let media):
            return "\(media.title) - \(media.artist)"
        }
    }

    private var compactAccentColor: Color {
        guard let currentActivity else {
            return Color(red: 0.39, green: 0.95, blue: 0.73)
        }

        return accentColor(for: .currentActivity(currentActivity))
    }

    private func accentColor(for anchor: IslandExpansionAnchor) -> Color {
        switch anchor {
        case .currentActivity(let activity):
            switch activity.presentation {
            case .generic:
                return Color(red: 0.39, green: 0.95, blue: 0.73)
            case .media:
                return Color(red: 0.95, green: 0.44, blue: 0.53)
            }
        case .idlePlaceholder:
            return Color(red: 0.39, green: 0.95, blue: 0.73)
        }
    }

    private func progressFraction(for media: MediaActivity) -> CGFloat {
        guard let duration = media.duration,
              let position = media.position,
              duration > 0 else {
            return 0
        }

        return min(max(CGFloat(position / duration), 0), 1)
    }

    private func image(from data: Data?) -> NSImage? {
        guard let data else {
            return nil
        }

        return NSImage(data: data)
    }
}

enum HomeDestination: Equatable {
    case media
    case fileShelf
    case clipboardHistory
    case settings
}
