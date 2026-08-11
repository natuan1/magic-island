import AppKit
import CryptoKit
import Foundation

enum ClipboardContentType: String, Equatable {
    case text
    case url
    case image
    case fileReference

    var title: String {
        switch self {
        case .text:
            return "Text"
        case .url:
            return "URL"
        case .image:
            return "Image"
        case .fileReference:
            return "File"
        }
    }
}

struct ClipboardHistoryItem: Equatable, Identifiable {
    let id: UUID
    let type: ClipboardContentType
    let title: String
    let contentHash: String
    let addedAt: Date
    let text: String?
    let fileURL: URL?
    let imageData: Data?

    var searchableText: String {
        [type.title, title, text, fileURL?.path]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

struct ClipboardSnapshot: Equatable {
    let type: ClipboardContentType
    let title: String
    let contentHash: String
    let text: String?
    let fileURL: URL?
    let imageData: Data?
}

final class ClipboardHistoryStore {
    private(set) var items: [ClipboardHistoryItem] = []

    @discardableResult
    func add(
        _ snapshot: ClipboardSnapshot,
        now: Date = Date(),
        idProvider: () -> UUID = UUID.init
    ) -> Bool {
        if let existingIndex = items.firstIndex(where: {
            $0.type == snapshot.type && $0.contentHash == snapshot.contentHash
        }) {
            let existing = items.remove(at: existingIndex)
            items.insert(existing, at: 0)
            return false
        }

        items.insert(ClipboardHistoryItem(
            id: idProvider(),
            type: snapshot.type,
            title: snapshot.title,
            contentHash: snapshot.contentHash,
            addedAt: now,
            text: snapshot.text,
            fileURL: snapshot.fileURL,
            imageData: snapshot.imageData
        ), at: 0)
        return true
    }

    func search(_ query: String) -> [ClipboardHistoryItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return items
        }

        return items.filter {
            $0.searchableText.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
    }

    @discardableResult
    func purgeExpired(now: Date = Date(), retentionDays: Int) -> Bool {
        let itemCount = items.count
        let cutoff = now.addingTimeInterval(-TimeInterval(max(1, retentionDays)) * 24 * 60 * 60)
        items.removeAll { $0.addedAt < cutoff }
        return items.count != itemCount
    }
}

protocol ClipboardProviding {
    var changeCount: Int { get }
    func snapshot() -> ClipboardSnapshot?
    func write(_ item: ClipboardHistoryItem)
}

struct ClipboardHistoryFeature<Provider: ClipboardProviding> {
    private var provider: Provider
    private var lastChangeCount: Int?
    private(set) var isPolling = false

    init(provider: Provider) {
        self.provider = provider
    }

    mutating func start() {
        isPolling = true
        lastChangeCount = provider.changeCount
    }

    mutating func stop() {
        isPolling = false
        lastChangeCount = nil
    }

    mutating func poll(
        store: ClipboardHistoryStore,
        settingsStore: SettingsStore,
        now: Date = Date()
    ) -> Bool {
        guard isPolling, settingsStore.isFeatureEnabled(.clipboardHistory) else {
            return false
        }

        let currentChangeCount = provider.changeCount
        guard currentChangeCount != lastChangeCount else {
            return false
        }

        lastChangeCount = currentChangeCount
        guard let snapshot = provider.snapshot() else {
            return false
        }

        let inserted = store.add(snapshot, now: now)
        let purged = store.purgeExpired(now: now, retentionDays: settingsStore.clipboardRetentionDays)
        return inserted || purged
    }

    func copy(_ item: ClipboardHistoryItem) {
        provider.write(item)
    }
}

struct MacPasteboardClipboardProvider: ClipboardProviding {
    var changeCount: Int {
        NSPasteboard.general.changeCount
    }

    func snapshot() -> ClipboardSnapshot? {
        let pasteboard = NSPasteboard.general

        if let fileURL = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )?.first as? URL {
            return ClipboardSnapshot(
                type: .fileReference,
                title: fileURL.lastPathComponent,
                contentHash: Self.hash(fileURL.path.data(using: .utf8) ?? Data()),
                text: nil,
                fileURL: fileURL,
                imageData: nil
            )
        }

        if let image = NSImage(pasteboard: pasteboard),
           let imageData = image.tiffRepresentation {
            return ClipboardSnapshot(
                type: .image,
                title: "Image",
                contentHash: Self.hash(imageData),
                text: nil,
                fileURL: nil,
                imageData: imageData
            )
        }

        guard let string = pasteboard.string(forType: .string), !string.isEmpty else {
            return nil
        }

        if let url = URL(string: string), url.scheme != nil {
            return ClipboardSnapshot(
                type: .url,
                title: string,
                contentHash: Self.hash(Data(string.utf8)),
                text: string,
                fileURL: url,
                imageData: nil
            )
        }

        return ClipboardSnapshot(
            type: .text,
            title: string,
            contentHash: Self.hash(Data(string.utf8)),
            text: string,
            fileURL: nil,
            imageData: nil
        )
    }

    func write(_ item: ClipboardHistoryItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text, .url:
            if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
        case .fileReference:
            if let fileURL = item.fileURL {
                pasteboard.writeObjects([fileURL as NSURL])
            }
        case .image:
            if let imageData = item.imageData,
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        }
    }

    static func hash(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
