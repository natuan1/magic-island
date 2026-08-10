import SwiftUI

struct IslandPlaceholderView: View {
    let size: CGSize
    let presentation: IslandPresentation

    init(
        size: CGSize = IslandWindowController.placeholderSize,
        presentation: IslandPresentation = .passive
    ) {
        self.size = size
        self.presentation = presentation
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
            compactContent(width: 54)
        case .peek:
            compactContent(width: 84)
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

    private func compactContent(width: CGFloat) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(red: 0.39, green: 0.95, blue: 0.73))
                .frame(width: 7, height: 7)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(.white.opacity(0.34))
                .frame(width: width, height: 6)
        }
    }

    private func expandedContent(anchor: IslandExpansionAnchor) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Circle()
                    .fill(Color(red: 0.39, green: 0.95, blue: 0.73))
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

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.white.opacity(0.16))
                    .frame(width: 72, height: 28)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.white.opacity(0.10))
                    .frame(width: 92, height: 28)
            }
        }
        .padding(22)
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
        case .currentActivity:
            return "Current Activity"
        case .idlePlaceholder:
            return "Idle"
        }
    }
}
