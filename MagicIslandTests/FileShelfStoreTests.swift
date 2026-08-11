import XCTest
@testable import MagicIsland

final class FileShelfStoreTests: XCTestCase {
    func testDroppingFilesCreatesReferenceShelfItemsByDefault() {
        let store = FileShelfStore()
        let now = Date()
        var ids = [
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        ]

        store.addFileReferences(
            [
                URL(fileURLWithPath: "/tmp/brief.pdf"),
                URL(fileURLWithPath: "/tmp/photo.png")
            ],
            now: now,
            idProvider: { ids.removeFirst() }
        )

        XCTAssertEqual(store.items.map(\.name), ["brief.pdf", "photo.png"])
        XCTAssertEqual(store.items.map(\.typeDescription), ["PDF", "PNG"])
        XCTAssertEqual(store.items.map(\.storageMode), [.reference, .reference])
        XCTAssertEqual(store.items.map(\.addedAt), [now, now])
    }

    func testMovedOrDeletedSourceFileIsReportedUnavailableWithoutCrashing() {
        let item = ShelfItem(
            id: UUID(),
            url: URL(fileURLWithPath: "/tmp/missing.mov"),
            name: "missing.mov",
            typeDescription: "MOV",
            storageMode: .reference,
            addedAt: Date()
        )

        XCTAssertFalse(item.isAvailable(fileExists: { _ in false }))
    }

    func testRepeatedFileDropsAppendReferencesWithoutReplacingExistingItems() {
        let store = FileShelfStore()
        var nextID = 0

        for index in 0..<1_000 {
            store.addFileReferences(
                [URL(fileURLWithPath: "/tmp/drop-\(index).txt")],
                idProvider: {
                    nextID += 1
                    return UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", nextID))!
                }
            )
        }

        XCTAssertEqual(store.items.count, 1_000)
        XCTAssertEqual(store.items.first?.name, "drop-0.txt")
        XCTAssertEqual(store.items.last?.name, "drop-999.txt")
    }
}
