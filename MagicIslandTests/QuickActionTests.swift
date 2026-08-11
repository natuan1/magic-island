import XCTest
@testable import MagicIsland

final class QuickActionTests: XCTestCase {
    func testTextItemsExposeCopyAndSearchActions() {
        let item = clipboardItem(type: .text, text: "Magic Island")
        let resolver = QuickActionResolver(providers: [ClipboardQuickActionProvider()])

        XCTAssertEqual(
            resolver.actions(for: .clipboard(item)).map(\.id),
            [.copyText, .searchText]
        )
    }

    func testURLItemsExposeOpenURLAction() {
        let item = clipboardItem(type: .url, text: "https://example.com")
        let resolver = QuickActionResolver(providers: [ClipboardQuickActionProvider()])

        XCTAssertEqual(
            resolver.actions(for: .clipboard(item)).map(\.id),
            [.copyText, .searchText, .openURL]
        )
    }

    func testTextContainingURLExposesOpenURLAction() {
        let item = clipboardItem(type: .text, text: "https://example.com")
        let resolver = QuickActionResolver(providers: [ClipboardQuickActionProvider()])

        XCTAssertEqual(
            resolver.actions(for: .clipboard(item)).map(\.id),
            [.copyText, .searchText, .openURL]
        )
    }

    func testShelfItemsExposeFileActions() {
        let item = shelfItem(URL(fileURLWithPath: "/tmp/report.pdf"))
        let resolver = QuickActionResolver(providers: [FileShelfQuickActionProvider()])

        XCTAssertEqual(
            resolver.actions(for: .shelf(item)).map(\.id),
            [.openFile, .previewFile, .revealFile, .copyPath]
        )
    }

    func testTextActionsExecuteThroughEnvironment() {
        let item = clipboardItem(type: .url, text: "https://example.com")
        let environment = SpyQuickActionEnvironment()
        let executor = QuickActionExecutor(environment: environment)

        XCTAssertEqual(executor.execute(.copyText, in: .clipboard(item)), .success("Copied text"))
        XCTAssertEqual(executor.execute(.searchText, in: .clipboard(item)), .success("Opened search"))
        XCTAssertEqual(executor.execute(.openURL, in: .clipboard(item)), .success("Opened URL"))
        XCTAssertEqual(environment.copiedText, ["https://example.com"])
        XCTAssertEqual(environment.searchedText, ["https://example.com"])
        XCTAssertEqual(environment.openedURLs, [URL(string: "https://example.com")!])
    }

    func testFileActionsExecuteThroughEnvironment() {
        let item = existingShelfItem()
        let environment = SpyQuickActionEnvironment()
        let executor = QuickActionExecutor(environment: environment)

        XCTAssertEqual(executor.execute(.openFile, in: .shelf(item)), .success("Opened file"))
        XCTAssertEqual(executor.execute(.previewFile, in: .shelf(item)), .success("Opened preview"))
        XCTAssertEqual(executor.execute(.revealFile, in: .shelf(item)), .success("Revealed file"))
        XCTAssertEqual(executor.execute(.copyPath, in: .shelf(item)), .success("Copied path"))
        XCTAssertEqual(environment.openedFiles, [item.url])
        XCTAssertEqual(environment.previewedFiles, [item.url])
        XCTAssertEqual(environment.revealedFiles, [item.url])
        XCTAssertEqual(environment.copiedText, [item.url.path])
    }

    func testFailedActionsReturnFeedbackInsteadOfThrowing() {
        let item = shelfItem(URL(fileURLWithPath: "/tmp/missing-\(UUID().uuidString).pdf"))
        let environment = SpyQuickActionEnvironment()
        environment.openFileResult = false
        let executor = QuickActionExecutor(environment: environment)

        XCTAssertEqual(
            executor.execute(.openFile, in: .shelf(item)),
            .failure("File unavailable")
        )
        XCTAssertEqual(
            executor.execute(.previewFile, in: .shelf(item)),
            .failure("File unavailable")
        )
        XCTAssertEqual(
            executor.execute(.revealFile, in: .shelf(item)),
            .failure("File unavailable")
        )
    }

    private func clipboardItem(type: ClipboardContentType, text: String) -> ClipboardHistoryItem {
        ClipboardHistoryItem(
            id: UUID(),
            type: type,
            title: text,
            contentHash: text,
            addedAt: Date(),
            text: text,
            fileURL: URL(string: text),
            imageData: nil
        )
    }

    private func shelfItem(_ url: URL) -> ShelfItem {
        ShelfItem(
            id: UUID(),
            url: url,
            name: url.lastPathComponent,
            typeDescription: url.pathExtension.uppercased(),
            storageMode: .reference,
            addedAt: Date()
        )
    }

    private func existingShelfItem() -> ShelfItem {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quick-action-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: url.path, contents: Data("test".utf8))
        return shelfItem(url)
    }
}

private final class SpyQuickActionEnvironment: QuickActionEnvironment {
    var copiedText: [String] = []
    var searchedText: [String] = []
    var openedURLs: [URL] = []
    var openedFiles: [URL] = []
    var previewedFiles: [URL] = []
    var revealedFiles: [URL] = []
    var openFileResult = true

    func copyText(_ text: String) -> Bool {
        copiedText.append(text)
        return true
    }

    func searchText(_ text: String) -> Bool {
        searchedText.append(text)
        return true
    }

    func openURL(_ url: URL) -> Bool {
        openedURLs.append(url)
        return true
    }

    func openFile(_ url: URL) -> Bool {
        openedFiles.append(url)
        return openFileResult
    }

    func previewFile(_ url: URL) -> Bool {
        previewedFiles.append(url)
        return true
    }

    func revealFile(_ url: URL) -> Bool {
        revealedFiles.append(url)
        return true
    }
}
