import Foundation

/// UserDefaults keys shared by the settings UI (@AppStorage) and the edge controller.
enum AppSettings {
    static let leftEdgeKey = "leftEdgeEnabled"
    static let rightEdgeKey = "rightEdgeEnabled"
    static let stripWidthKey = "stripWidth"
    static let activeZoneKey = "activeZone"
    static let allDisplaysKey = "allDisplays"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            leftEdgeKey: true,
            rightEdgeKey: true,
            stripWidthKey: 10.0,
            activeZoneKey: 0.7,
            allDisplaysKey: false,
        ])
    }

    static var enabledEdges: [ScreenEdge] {
        let d = UserDefaults.standard
        var edges: [ScreenEdge] = []
        if d.bool(forKey: leftEdgeKey) { edges.append(.left) }
        if d.bool(forKey: rightEdgeKey) { edges.append(.right) }
        return edges
    }

    /// Width in points of the invisible strip that catches the thumb.
    static var stripWidth: CGFloat { CGFloat(UserDefaults.standard.double(forKey: stripWidthKey)) }

    /// Fraction of the screen height (centered) where a swipe can start. Keeps the
    /// corners free for the menu bar, Dock and window controls.
    static var activeZone: CGFloat { CGFloat(UserDefaults.standard.double(forKey: activeZoneKey)) }

    static var allDisplays: Bool { UserDefaults.standard.bool(forKey: allDisplaysKey) }
}
