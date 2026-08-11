import AppKit
import SwiftUI

struct IslandPlaceholderView: View {
    let size: CGSize
    let presentation: IslandPresentation
    let currentActivity: CurrentActivity?
    let onMediaCommand: (MediaCommand) -> Void
    let onTimerCommand: (TimerCommand) -> Void
    let selectedHomeDestination: HomeDestination?
    let availableHomeDestinations: [HomeDestination]
    let fileShelfItems: [ShelfItem]
    let onHomeSelection: (HomeDestination) -> Void
    let onRevealShelfItem: (UUID) -> Void
    let clipboardItems: [ClipboardHistoryItem]
    let onCopyClipboardItem: (UUID) -> Void
    let onDeleteClipboardItem: (UUID) -> Void
    let quickActionsProvider: (QuickActionContext) -> [QuickAction]
    let quickActionHandler: (QuickActionID, QuickActionContext) -> QuickActionResult

    @State private var clipboardSearchQuery = ""
    @State private var quickActionFeedback: String?

    init(
        size: CGSize = IslandWindowController.placeholderSize,
        presentation: IslandPresentation = .passive,
        currentActivity: CurrentActivity? = nil,
        onMediaCommand: @escaping (MediaCommand) -> Void = { _ in },
        onTimerCommand: @escaping (TimerCommand) -> Void = { _ in },
        selectedHomeDestination: HomeDestination? = nil,
        availableHomeDestinations: [HomeDestination] = [.media, .fileShelf, .settings],
        fileShelfItems: [ShelfItem] = [],
        onHomeSelection: @escaping (HomeDestination) -> Void = { _ in },
        onRevealShelfItem: @escaping (UUID) -> Void = { _ in },
        clipboardItems: [ClipboardHistoryItem] = [],
        onCopyClipboardItem: @escaping (UUID) -> Void = { _ in },
        onDeleteClipboardItem: @escaping (UUID) -> Void = { _ in },
        quickActionsProvider: @escaping (QuickActionContext) -> [QuickAction] = { _ in [] },
        quickActionHandler: @escaping (QuickActionID, QuickActionContext) -> QuickActionResult = { _, _ in .failure("Action unavailable") }
    ) {
        self.size = size
        self.presentation = presentation
        self.currentActivity = currentActivity
        self.onMediaCommand = onMediaCommand
        self.onTimerCommand = onTimerCommand
        self.selectedHomeDestination = selectedHomeDestination
        self.availableHomeDestinations = availableHomeDestinations
        self.fileShelfItems = fileShelfItems
        self.onHomeSelection = onHomeSelection
        self.onRevealShelfItem = onRevealShelfItem
        self.clipboardItems = clipboardItems
        self.onCopyClipboardItem = onCopyClipboardItem
        self.onDeleteClipboardItem = onDeleteClipboardItem
        self.quickActionsProvider = quickActionsProvider
        self.quickActionHandler = quickActionHandler
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
        case .dragTarget:
            dragTargetContent
        case .expanded(let anchor):
            expandedContent(anchor: anchor)
        }
    }

    private var cornerRadius: CGFloat {
        switch presentation {
        case .expanded:
            return 22
        case .passive, .peek, .dragTarget, .collapsing:
            return size.height / 2
        }
    }

    private var accessibilityLabel: String {
        switch presentation {
        case .passive:
            return "Magic Island passive"
        case .peek:
            return "Magic Island peek"
        case .dragTarget:
            return "Magic Island drag target"
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

    private var dragTargetContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.39, green: 0.95, blue: 0.73))

            Text("Drop files")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
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

            if let quickActionFeedback {
                Text(quickActionFeedback)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }

            expandedDetail(for: anchor)

            homeNavigation
        }
        .padding(22)
    }

    @ViewBuilder
    private func expandedDetail(for anchor: IslandExpansionAnchor) -> some View {
        switch selectedHomeDestination {
        case .fileShelf:
            fileShelfDetail
        case .clipboardHistory:
            clipboardHistoryDetail
        case .timer:
            selectedTimerDetail(anchor: anchor)
        case .media, .settings, nil:
            activityDetail(for: anchor)
        }
    }

    @ViewBuilder
    private func selectedTimerDetail(anchor: IslandExpansionAnchor) -> some View {
        if case .currentActivity(let activity) = anchor,
           case .timer(let timer) = activity.presentation {
            timerDetail(timer)
        } else {
            timerStartDetail
        }
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
            case .timer(let timer):
                timerDetail(timer)
            }
        case .idlePlaceholder:
            Spacer(minLength: 0)
        }
    }

    private var timerStartDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                timerStartButton(title: "5m", duration: 5 * 60)
                timerStartButton(title: "10m", duration: 10 * 60)
                timerStartButton(title: "25m", duration: 25 * 60)
            }

            Text("Start timer")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func timerStartButton(title: String, duration: TimeInterval) -> some View {
        Button(action: { onTimerCommand(.start(duration)) }) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 54, height: 30)
        }
        .buttonStyle(.plain)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityLabel("Start \(title) timer")
    }

    private var fileShelfDetail: some View {
        VStack(alignment: .leading, spacing: 8) {
            if fileShelfItems.isEmpty {
                Text("File Shelf empty")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(fileShelfItems) { item in
                            shelfRow(item)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func shelfRow(_ item: ShelfItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isAvailable() ? "doc" : "exclamationmark.triangle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(item.isAvailable() ? .white.opacity(0.72) : Color(red: 0.95, green: 0.72, blue: 0.32))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(item.isAvailable() ? 0.86 : 0.42))
                    .lineLimit(1)
                Text(item.isAvailable() ? "\(item.typeDescription) reference" : "Missing source")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.46))
                    .lineLimit(1)
            }

            Spacer()

            quickActionButtons(context: .shelf(item), isEnabled: item.isAvailable())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .onDrag {
            NSItemProvider(contentsOf: item.url) ?? NSItemProvider(object: item.url.path as NSString)
        }
    }

    private var clipboardHistoryDetail: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search", text: $clipboardSearchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            let visibleItems = filteredClipboardItems
            if visibleItems.isEmpty {
                Text("Clipboard History empty")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(visibleItems.prefix(3)) { item in
                    clipboardRow(item)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var filteredClipboardItems: [ClipboardHistoryItem] {
        let query = clipboardSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return clipboardItems
        }

        return clipboardItems.filter {
            $0.searchableText.localizedCaseInsensitiveContains(query)
        }
    }

    private func clipboardRow(_ item: ClipboardHistoryItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconName(for: item.type))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                Text(item.type.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.46))
                    .lineLimit(1)
            }

            Spacer()

            quickActionButtons(context: .clipboard(item))

            Button(action: { onDeleteClipboardItem(item.id) }) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.64))
                    .frame(width: 25, height: 23)
            }
            .buttonStyle(.plain)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .help("Delete")
            .accessibilityLabel("Delete \(item.title)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func quickActionButtons(context: QuickActionContext, isEnabled: Bool = true) -> some View {
        HStack(spacing: 5) {
            ForEach(quickActionsProvider(context).prefix(4)) { action in
                Button(action: { runQuickAction(action.id, context: context) }) {
                    Image(systemName: action.systemImageName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(isEnabled ? 0.74 : 0.28))
                        .frame(width: 25, height: 23)
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .disabled(!isEnabled)
                .help(action.title)
                .accessibilityLabel(action.title)
            }
        }
    }

    private func runQuickAction(_ actionID: QuickActionID, context: QuickActionContext) {
        let result = quickActionHandler(actionID, context)
        quickActionFeedback = result.message
    }

    private func iconName(for type: ClipboardContentType) -> String {
        switch type {
        case .text:
            return "text.alignleft"
        case .url:
            return "link"
        case .image:
            return "photo"
        case .fileReference:
            return "doc"
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

    private func timerDetail(_ timer: TimerActivity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(TimerDurationFormatter.string(from: timer.remainingTime))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .monospacedDigit()

            HStack(spacing: 8) {
                switch timer.state {
                case .running:
                    timerCommandButton("pause.fill", command: .pause)
                    timerCommandButton("arrow.clockwise", command: .restart)
                    timerCommandButton("xmark", command: .cancel)
                    timerCommandButton("xmark.circle", command: .close)
                case .paused:
                    timerCommandButton("play.fill", command: .resume)
                    timerCommandButton("arrow.clockwise", command: .restart)
                    timerCommandButton("xmark", command: .cancel)
                    timerCommandButton("xmark.circle", command: .close)
                case .completed:
                    timerCommandButton("arrow.clockwise", command: .restart)
                    timerCommandButton("xmark", command: .close)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func timerCommandButton(_ systemName: String, command: TimerCommand) -> some View {
        Button(action: { onTimerCommand(command) }) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 34, height: 30)
        }
        .buttonStyle(.plain)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityLabel(accessibilityLabel(for: command))
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
        .accessibilityLabel(accessibilityLabel(for: command))
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
        .accessibilityLabel("Seek forward 15 seconds")
    }

    private var homeNavigation: some View {
        HStack(spacing: 8) {
            ForEach(availableHomeDestinations, id: \.self) { destination in
                homeNavigationItem(destination, systemName: iconName(for: destination))
            }
        }
    }

    private func iconName(for destination: HomeDestination) -> String {
        switch destination {
        case .media:
            return "music.note"
        case .fileShelf:
            return "folder"
        case .clipboardHistory:
            return "doc.on.clipboard"
        case .timer:
            return "timer"
        case .settings:
            return "gearshape"
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
        .help(destination.title)
        .accessibilityLabel(destination.title)
    }

    private func accessibilityLabel(for command: TimerCommand) -> String {
        switch command {
        case .start(let duration):
            return "Start \(Int(duration / 60)) minute timer"
        case .pause:
            return "Pause timer"
        case .resume:
            return "Resume timer"
        case .restart:
            return "Restart timer"
        case .cancel:
            return "Cancel timer"
        case .close:
            return "Close timer"
        }
    }

    private func accessibilityLabel(for command: MediaCommand) -> String {
        switch command {
        case .playPause:
            return "Play or pause media"
        case .previous:
            return "Previous track"
        case .next:
            return "Next track"
        case .seek:
            return "Seek media"
        }
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
        case .timer(let timer):
            return TimerDurationFormatter.string(from: timer.remainingTime)
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
            case .timer:
                return Color(red: 0.42, green: 0.78, blue: 1.0)
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
    case timer
    case settings

    var title: String {
        switch self {
        case .media:
            return "Media"
        case .fileShelf:
            return "File Shelf"
        case .clipboardHistory:
            return "Clipboard History"
        case .timer:
            return "Timer"
        case .settings:
            return "Settings"
        }
    }
}
