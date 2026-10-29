import SwiftUI

/// Laid out for a thumb gripping the edge: the sliders sit nearest the edge you
/// swiped from, and every target is at least ~56pt.
struct PanelView: View {
    @ObservedObject var state: PanelState
    let services: Services

    @AppStorage(AppSettings.tilesKey(.left)) private var leftTiles = TileKind.defaultLayout
    @AppStorage(AppSettings.tilesKey(.right)) private var rightTiles = TileKind.defaultLayout

    private var tiles: [TileKind] {
        TileKind.decode(state.edge == .left ? leftTiles : rightTiles)
    }

    var body: some View {
        HStack(spacing: 10) {
            if state.edge == .left { grabber }
            content
            if state.edge == .right { grabber }
        }
        .padding(14)
        .frame(width: PanelWindow.size.width, height: PanelWindow.size.height)
    }

    private var content: some View {
        VStack(spacing: 12) {
            if tiles.isEmpty {
                Text("No tiles on this edge. Turn some on in Thumbrail's settings.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: .infinity)
            }
            ForEach(tiles) { tile($0) }
            // The clipboard grows to fill the panel; without it, stack tiles from the top.
            if !tiles.isEmpty && !tiles.contains(.clipboard) { Spacer(minLength: 0) }
        }
    }

    @ViewBuilder
    private func tile(_ kind: TileKind) -> some View {
        switch kind {
        case .battery:
            BatteryCard(battery: services.battery)
        case .sliders:
            SlidersRow(volume: services.volume, brightness: services.brightness, edge: state.edge)
                .frame(height: 200)
        case .media:
            MediaControls(media: services.media)
        case .clipboard:
            ClipboardList(clipboard: services.clipboard)
        }
    }

    /// Tap, or drag back toward the edge, to put the panel away.
    private var grabber: some View {
        Capsule()
            .fill(.secondary.opacity(0.6))
            .frame(width: 5, height: 56)
            .frame(maxHeight: .infinity)
            .frame(width: 18)
            .contentShape(Rectangle())
            .onTapGesture { state.onClose() }
            .gesture(DragGesture(minimumDistance: 10).onEnded { value in
                let towardEdge = state.edge == .left ? -value.translation.width : value.translation.width
                if towardEdge > 30 { state.onClose() }
            })
    }
}

struct Tile<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
