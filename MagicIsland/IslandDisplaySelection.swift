import CoreGraphics

enum IslandDisplaySelection {
    static func primaryDisplayFrame(
        from screenFrames: [CGRect],
        mainScreenFrame: CGRect?
    ) -> CGRect? {
        screenFrames.first { $0.origin == .zero }
            ?? mainScreenFrame
            ?? screenFrames.first
    }

    static func selectedDisplay(
        from displays: [IslandDisplayDescriptor],
        selectedDisplayID: UInt32?,
        primaryDisplayID: UInt32?
    ) -> IslandDisplayDescriptor? {
        if let selectedDisplayID,
           let selectedDisplay = displays.first(where: { $0.id == selectedDisplayID }) {
            return selectedDisplay
        }

        if let primaryDisplayID,
           let primaryDisplay = displays.first(where: { $0.id == primaryDisplayID }) {
            return primaryDisplay
        }

        return displays.first { $0.frame.origin == .zero }
            ?? displays.first
    }
}
