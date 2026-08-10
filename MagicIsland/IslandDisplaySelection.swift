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
}
