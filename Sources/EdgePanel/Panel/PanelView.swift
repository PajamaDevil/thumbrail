import SwiftUI

/// Laid out for a thumb gripping the edge: the sliders sit nearest the edge you
/// swiped from, and every target is at least ~56pt.
struct PanelView: View {
    @ObservedObject var state: PanelState
    let services: Services

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
            BatteryCard(battery: services.battery)
            SlidersRow(volume: services.volume, brightness: services.brightness, edge: state.edge)
                .frame(height: 200)
            MediaControls(media: services.media)
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
