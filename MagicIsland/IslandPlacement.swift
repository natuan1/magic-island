import CoreGraphics

struct DisplaySafeAreaInsets: Equatable {
    static let zero = DisplaySafeAreaInsets(top: 0, left: 0, bottom: 0, right: 0)

    let top: CGFloat
    let left: CGFloat
    let bottom: CGFloat
    let right: CGFloat
}

struct IslandDisplayDescriptor: Equatable {
    let id: UInt32?
    let frame: CGRect
    let visibleFrame: CGRect
    let safeAreaInsets: DisplaySafeAreaInsets
    let auxiliaryTopLeftArea: CGRect
    let auxiliaryTopRightArea: CGRect

    init(
        id: UInt32? = nil,
        frame: CGRect,
        visibleFrame: CGRect? = nil,
        safeAreaInsets: DisplaySafeAreaInsets,
        auxiliaryTopLeftArea: CGRect,
        auxiliaryTopRightArea: CGRect
    ) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame ?? frame
        self.safeAreaInsets = safeAreaInsets
        self.auxiliaryTopLeftArea = auxiliaryTopLeftArea
        self.auxiliaryTopRightArea = auxiliaryTopRightArea
    }
}

enum IslandGeometryKind: Equatable {
    case physicalNotch
    case floatingIsland
}

struct IslandPlacementResult: Equatable {
    let kind: IslandGeometryKind
    let frame: CGRect
}

enum IslandPlacement {
    static let floatingIslandSize = CGSize(width: 148, height: 38)
    static let topInset: CGFloat = 8

    static func frame(for display: IslandDisplayDescriptor) -> IslandPlacementResult {
        if let notchFrame = physicalNotchFrame(for: display) {
            return IslandPlacementResult(kind: .physicalNotch, frame: notchFrame)
        }

        return IslandPlacementResult(
            kind: .floatingIsland,
            frame: floatingIslandFrame(in: display.frame)
        )
    }

    static func placeholderFrame(
        in displayFrame: CGRect,
        islandSize: CGSize
    ) -> CGRect {
        floatingIslandFrame(in: displayFrame, islandSize: islandSize)
    }

    static func clampedFrame(_ frame: CGRect, to bounds: CGRect) -> CGRect {
        guard !bounds.isEmpty else {
            return frame
        }

        let width = min(frame.width, bounds.width)
        let height = min(frame.height, bounds.height)
        let minX = bounds.minX
        let maxX = bounds.maxX - width
        let minY = bounds.minY
        let maxY = bounds.maxY - height

        return CGRect(
            x: min(max(frame.minX, minX), maxX),
            y: min(max(frame.minY, minY), maxY),
            width: width,
            height: height
        )
    }

    private static func floatingIslandFrame(
        in displayFrame: CGRect,
        islandSize: CGSize = floatingIslandSize
    ) -> CGRect {
        CGRect(
            x: displayFrame.midX - (islandSize.width / 2),
            y: displayFrame.maxY - islandSize.height - topInset,
            width: islandSize.width,
            height: islandSize.height
        )
    }

    private static func physicalNotchFrame(for display: IslandDisplayDescriptor) -> CGRect? {
        guard
            display.safeAreaInsets.top > 0,
            !display.auxiliaryTopLeftArea.isEmpty,
            !display.auxiliaryTopRightArea.isEmpty,
            display.auxiliaryTopRightArea.minX > display.auxiliaryTopLeftArea.maxX
        else {
            return nil
        }

        let notchWidth = display.auxiliaryTopRightArea.minX - display.auxiliaryTopLeftArea.maxX
        let notchHeight = max(
            display.safeAreaInsets.top,
            display.auxiliaryTopLeftArea.height,
            display.auxiliaryTopRightArea.height
        )

        return CGRect(
            x: display.auxiliaryTopLeftArea.maxX,
            y: display.frame.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
    }
}
