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
}
