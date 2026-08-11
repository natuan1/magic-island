import XCTest
@testable import MagicIsland

final class ClipboardHistoryTests: XCTestCase {
    func testItemsAreDeduplicatedByTypeAndContentHash() {
        let store = ClipboardHistoryStore()
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let snapshot = ClipboardSnapshot(
            type: .text,
            title: "Hello",
            contentHash: "abc",
            text: "Hello",
            fileURL: nil,
            imageData: nil
        )

        XCTAssertTrue(store.add(snapshot, idProvider: { firstID }))
        XCTAssertFalse(store.add(snapshot, idProvider: UUID.init))

        XCTAssertEqual(store.items.map(\.id), [firstID])
    }

    func testRetentionRemovesExpiredItems() {
        let store = ClipboardHistoryStore()
        let now = Date(timeIntervalSince1970: 10 * 24 * 60 * 60)

        store.add(snapshot("old"), now: now.addingTimeInterval(-8 * 24 * 60 * 60))
        store.add(snapshot("fresh"), now: now.addingTimeInterval(-6 * 24 * 60 * 60))

        XCTAssertTrue(store.purgeExpired(now: now, retentionDays: 7))

        XCTAssertEqual(store.items.map(\.title), ["fresh"])
    }

    func testPollingRunsOnlyWhenEnabledAndChangeCountChanges() {
        let defaults = UserDefaults(suiteName: "ClipboardHistoryTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.clipboardHistory, enabled: false)
        let provider = SpyClipboardProvider(
            changeCount: 1,
            nextSnapshot: snapshot("Secret")
        )
        var feature = ClipboardHistoryFeature(provider: provider)
        let store = ClipboardHistoryStore()

        feature.start()

        XCTAssertFalse(feature.poll(store: store, settingsStore: settingsStore))
        XCTAssertEqual(provider.snapshotReadCount, 0)

        settingsStore.setFeature(.clipboardHistory, enabled: true)
        XCTAssertFalse(feature.poll(store: store, settingsStore: settingsStore))
        XCTAssertEqual(provider.snapshotReadCount, 0)

        provider.changeCount = 2
        XCTAssertTrue(feature.poll(store: store, settingsStore: settingsStore))
        XCTAssertEqual(provider.snapshotReadCount, 1)
        XCTAssertEqual(store.items.map(\.title), ["Secret"])
    }

    func testPollingReportsChangeWhenRetentionPurgesExpiredItems() {
        let defaults = UserDefaults(suiteName: "ClipboardHistoryTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.clipboardHistory, enabled: true)
        settingsStore.clipboardRetentionDays = 7
        let now = Date(timeIntervalSince1970: 10 * 24 * 60 * 60)
        let duplicateSnapshot = snapshot("Fresh")
        let provider = SpyClipboardProvider(changeCount: 1, nextSnapshot: duplicateSnapshot)
        var feature = ClipboardHistoryFeature(provider: provider)
        let store = ClipboardHistoryStore()
        store.add(snapshot("Old"), now: now.addingTimeInterval(-8 * 24 * 60 * 60))
        store.add(duplicateSnapshot, now: now)

        feature.start()
        provider.changeCount = 2

        XCTAssertTrue(feature.poll(store: store, settingsStore: settingsStore, now: now))
        XCTAssertEqual(store.items.map(\.title), ["Fresh"])
    }


    func testSearchAndDeleteUseVisibleLocalItems() {
        let store = ClipboardHistoryStore()
        store.add(snapshot("Deploy notes"))
        store.add(snapshot("Lunch"))

        XCTAssertEqual(store.search("deploy").map(\.title), ["Deploy notes"])

        let itemID = store.items[0].id
        store.delete(id: itemID)

        XCTAssertEqual(store.items.map(\.title), ["Deploy notes"])
    }

    func testRepeatedClipboardCapturesDeduplicateAndKeepPollingStateBounded() {
        let defaults = UserDefaults(suiteName: "ClipboardHistoryTests.\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.setFeature(.clipboardHistory, enabled: true)
        let provider = SpyClipboardProvider(changeCount: 0, nextSnapshot: snapshot("Repeated"))
        var feature = ClipboardHistoryFeature(provider: provider)
        let store = ClipboardHistoryStore()

        feature.start()

        for changeCount in 1...1_000 {
            provider.changeCount = changeCount
            XCTAssertEqual(feature.poll(store: store, settingsStore: settingsStore), changeCount == 1)
        }

        XCTAssertEqual(provider.snapshotReadCount, 1_000)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.title, "Repeated")
    }

    private func snapshot(_ text: String) -> ClipboardSnapshot {
        ClipboardSnapshot(
            type: .text,
            title: text,
            contentHash: text,
            text: text,
            fileURL: nil,
            imageData: nil
        )
    }
}

private final class SpyClipboardProvider: ClipboardProviding {
    var changeCount: Int
    var nextSnapshot: ClipboardSnapshot?
    var snapshotReadCount = 0
    var copiedItems: [ClipboardHistoryItem] = []

    init(changeCount: Int, nextSnapshot: ClipboardSnapshot?) {
        self.changeCount = changeCount
        self.nextSnapshot = nextSnapshot
    }

    func snapshot() -> ClipboardSnapshot? {
        snapshotReadCount += 1
        return nextSnapshot
    }

    func write(_ item: ClipboardHistoryItem) {
        copiedItems.append(item)
    }
}
