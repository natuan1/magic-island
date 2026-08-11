import AppKit
import Foundation

protocol MotionPreferenceProviding {
    var reduceMotionEnabled: Bool { get }
}

struct SystemMotionPreferenceProvider: MotionPreferenceProviding {
    var reduceMotionEnabled: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
}

struct IslandMotionPolicy: Equatable {
    let reduceMotionEnabled: Bool

    var animatesGeometryChanges: Bool {
        !reduceMotionEnabled
    }
}

struct IslandPresentationLayout: Equatable {
    static func size(for presentation: IslandPresentation) -> CGSize {
        switch presentation {
        case .passive, .dragTarget, .collapsing:
            return IslandPlacement.floatingIslandSize
        case .peek:
            return CGSize(width: 184, height: 46)
        case .expanded:
            return CGSize(width: 420, height: 220)
        }
    }
}
