import Foundation

enum ShelfStorageMode: Equatable {
    case reference
}

struct ShelfItem: Equatable, Identifiable {
    let id: UUID
    let url: URL
    let name: String
    let typeDescription: String
    let storageMode: ShelfStorageMode
    let addedAt: Date

    func isAvailable(fileExists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }) -> Bool {
        fileExists(url)
    }
}

final class FileShelfStore {
    private(set) var items: [ShelfItem] = []

    func addFileReferences(
        _ urls: [URL],
        now: Date = Date(),
        idProvider: () -> UUID = UUID.init
    ) {
        let newItems = urls.map { url in
            ShelfItem(
                id: idProvider(),
                url: url,
                name: url.lastPathComponent,
                typeDescription: Self.typeDescription(for: url),
                storageMode: .reference,
                addedAt: now
            )
        }

        items.append(contentsOf: newItems)
    }

    func item(id: UUID) -> ShelfItem? {
        items.first { $0.id == id }
    }

    private static func typeDescription(for url: URL) -> String {
        guard !url.pathExtension.isEmpty else {
            return "File"
        }

        return url.pathExtension.uppercased()
    }
}
