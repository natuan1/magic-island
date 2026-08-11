import AppKit
import Foundation

enum QuickActionID: String, Equatable {
    case copyText
    case searchText
    case openURL
    case openFile
    case previewFile
    case revealFile
    case copyPath
}

struct QuickAction: Equatable, Identifiable {
    let id: QuickActionID
    let title: String
    let systemImageName: String
}

enum QuickActionContext: Equatable {
    case clipboard(ClipboardHistoryItem)
    case shelf(ShelfItem)
}

protocol QuickActionProviding {
    func actions(for context: QuickActionContext) -> [QuickAction]
}

struct QuickActionResolver {
    private let providers: [any QuickActionProviding]

    init(providers: [any QuickActionProviding]) {
        self.providers = providers
    }

    func actions(for context: QuickActionContext) -> [QuickAction] {
        providers.flatMap { $0.actions(for: context) }
    }
}

struct ClipboardQuickActionProvider: QuickActionProviding {
    func actions(for context: QuickActionContext) -> [QuickAction] {
        guard case .clipboard(let item) = context,
              item.text != nil else {
            return []
        }

        var actions = [
            QuickAction(id: .copyText, title: "Copy", systemImageName: "doc.on.doc"),
            QuickAction(id: .searchText, title: "Search Web", systemImageName: "magnifyingglass")
        ]

        if item.urlValue != nil {
            actions.append(QuickAction(id: .openURL, title: "Open URL", systemImageName: "link"))
        }

        return actions
    }
}

struct FileShelfQuickActionProvider: QuickActionProviding {
    func actions(for context: QuickActionContext) -> [QuickAction] {
        guard case .shelf = context else {
            return []
        }

        return [
            QuickAction(id: .openFile, title: "Open", systemImageName: "arrow.up.right.square"),
            QuickAction(id: .previewFile, title: "Preview", systemImageName: "eye"),
            QuickAction(id: .revealFile, title: "Reveal", systemImageName: "folder"),
            QuickAction(id: .copyPath, title: "Copy Path", systemImageName: "doc.on.doc")
        ]
    }
}

enum QuickActionResult: Equatable {
    case success(String)
    case failure(String)

    var message: String {
        switch self {
        case .success(let message), .failure(let message):
            return message
        }
    }
}

protocol QuickActionEnvironment: AnyObject {
    func copyText(_ text: String) -> Bool
    func searchText(_ text: String) -> Bool
    func openURL(_ url: URL) -> Bool
    func openFile(_ url: URL) -> Bool
    func previewFile(_ url: URL) -> Bool
    func revealFile(_ url: URL) -> Bool
}

struct QuickActionExecutor {
    private let environment: QuickActionEnvironment

    init(environment: QuickActionEnvironment) {
        self.environment = environment
    }

    func execute(_ actionID: QuickActionID, in context: QuickActionContext) -> QuickActionResult {
        switch (actionID, context) {
        case (.copyText, .clipboard(let item)):
            guard let text = item.text else {
                return .failure("Nothing to copy")
            }
            return environment.copyText(text) ? .success("Copied text") : .failure("Could not copy text")
        case (.searchText, .clipboard(let item)):
            guard let text = item.text else {
                return .failure("Nothing to search")
            }
            return environment.searchText(text) ? .success("Opened search") : .failure("Could not open search")
        case (.openURL, .clipboard(let item)):
            guard let url = item.urlValue else {
                return .failure("No URL to open")
            }
            return environment.openURL(url) ? .success("Opened URL") : .failure("Could not open URL")
        case (.openFile, .shelf(let item)):
            guard item.isAvailable() else {
                return .failure("File unavailable")
            }
            return environment.openFile(item.url) ? .success("Opened file") : .failure("Could not open file")
        case (.previewFile, .shelf(let item)):
            guard item.isAvailable() else {
                return .failure("File unavailable")
            }
            return environment.previewFile(item.url) ? .success("Opened preview") : .failure("Could not preview file")
        case (.revealFile, .shelf(let item)):
            guard item.isAvailable() else {
                return .failure("File unavailable")
            }
            return environment.revealFile(item.url) ? .success("Revealed file") : .failure("Could not reveal file")
        case (.copyPath, .shelf(let item)):
            return environment.copyText(item.url.path) ? .success("Copied path") : .failure("Could not copy path")
        default:
            return .failure("Action unavailable")
        }
    }
}

final class MacQuickActionEnvironment: QuickActionEnvironment {
    func copyText(_ text: String) -> Bool {
        NSPasteboard.general.clearContents()
        return NSPasteboard.general.setString(text, forType: .string)
    }

    func searchText(_ text: String) -> Bool {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: text)]
        guard let url = components?.url else {
            return false
        }
        return NSWorkspace.shared.open(url)
    }

    func openURL(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    func openFile(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    func previewFile(_ url: URL) -> Bool {
        let previewApp = URL(fileURLWithPath: "/System/Applications/Preview.app")
        guard FileManager.default.fileExists(atPath: previewApp.path) else {
            return NSWorkspace.shared.open(url)
        }
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: previewApp,
            configuration: NSWorkspace.OpenConfiguration()
        )
        return true
    }

    func revealFile(_ url: URL) -> Bool {
        NSWorkspace.shared.activateFileViewerSelecting([url])
        return true
    }

}

extension ClipboardHistoryItem {
    var urlValue: URL? {
        switch type {
        case .text, .url:
            guard let text else {
                return nil
            }
            guard let url = URL(string: text),
                  url.scheme != nil else {
                return nil
            }
            return url
        case .fileReference:
            return fileURL
        case .image:
            return nil
        }
    }
}

extension ClipboardHistoryFeature {
    static var quickActionProvider: ClipboardQuickActionProvider {
        ClipboardQuickActionProvider()
    }
}

struct FileShelfFeature {
    static var quickActionProvider: FileShelfQuickActionProvider {
        FileShelfQuickActionProvider()
    }
}
