import Foundation

/// The tiles a panel can show. Each edge keeps its own ordered list of the ones
/// that are turned on, stored in UserDefaults as comma-separated raw values.
enum TileKind: String, CaseIterable, Identifiable {
    case battery, sliders, media, clipboard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .battery: return "Battery"
        case .sliders: return "Volume & brightness"
        case .media: return "Music controls"
        case .clipboard: return "Clipboard"
        }
    }

    var systemImage: String {
        switch self {
        case .battery: return "battery.100"
        case .sliders: return "slider.vertical.3"
        case .media: return "playpause.fill"
        case .clipboard: return "doc.on.clipboard"
        }
    }

    static let defaultLayout = encode(allCases)

    /// Unknown names are dropped and duplicates keep their first position.
    static func decode(_ layout: String) -> [TileKind] {
        var seen = Set<TileKind>()
        return layout.split(separator: ",").compactMap { name in
            guard let kind = TileKind(rawValue: String(name)), seen.insert(kind).inserted else { return nil }
            return kind
        }
    }

    static func encode(_ tiles: [TileKind]) -> String {
        tiles.map(\.rawValue).joined(separator: ",")
    }
}
