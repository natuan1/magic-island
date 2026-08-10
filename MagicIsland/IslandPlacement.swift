import CoreGraphics

enum IslandPlacement {
    static let topInset: CGFloat = 8

    static func placeholderFrame(
        in displayFrame: CGRect,
        islandSize: CGSize
    ) -> CGRect {
        CGRect(
            x: displayFrame.midX - (islandSize.width / 2),
            y: displayFrame.maxY - islandSize.height - topInset,
            width: islandSize.width,
            height: islandSize.height
        )
    }
}
