import ServiceManagement
import SwiftUI

struct SettingsView: View {
    let controller: EdgeController

    @AppStorage(AppSettings.leftEdgeKey) private var leftEdge = true
    @AppStorage(AppSettings.rightEdgeKey) private var rightEdge = true
    @AppStorage(AppSettings.stripWidthKey) private var stripWidth = 10.0
    @AppStorage(AppSettings.activeZoneKey) private var activeZone = 0.7
    @AppStorage(AppSettings.allDisplaysKey) private var allDisplays = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage(AppSettings.tileEditorEdgeKey) private var tileEditorEdge = ScreenEdge.right

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thumbrail").font(.headline)

            Toggle("Left edge", isOn: $leftEdge)
            Toggle("Right edge", isOn: $rightEdge)
            Toggle("All displays (not just the built-in one)", isOn: $allDisplays)

            VStack(alignment: .leading, spacing: 4) {
                Text("Edge strip width: \(Int(stripWidth)) pt")
                Slider(value: $stripWidth, in: 4...24, step: 1)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Swipe zone: middle \(Int(activeZone * 100))% of the edge")
                Slider(value: $activeZone, in: 0.3...1.0, step: 0.05)
            }

            HStack {
                Button("Open left") { controller.toggle(edge: .left) }
                Button("Open right") { controller.toggle(edge: .right) }
            }
            Text("Shortcut: ⌃⌥← / ⌃⌥→. With a mouse, press at the very edge of the screen and drag inward.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text("Tiles").font(.headline)
            Picker("Edge", selection: $tileEditorEdge) {
                Text("Left panel").tag(ScreenEdge.left)
                Text("Right panel").tag(ScreenEdge.right)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            TileListEditor(edge: tileEditorEdge)
                .id(tileEditorEdge)

            Divider()

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    // Only works when running from the .app bundle (Scripts/make-app.sh).
                    if enabled {
                        try? SMAppService.mainApp.register()
                    } else {
                        try? SMAppService.mainApp.unregister()
                    }
                }

            Button("Quit Thumbrail") { NSApp.terminate(nil) }
        }
        .padding(16)
        .frame(width: 300)
    }
}

/// Turn tiles on or off for one edge and move them up or down. Tiles that are on
/// come first, in panel order; the ones that are off are listed after them.
struct TileListEditor: View {
    @AppStorage private var layout: String

    init(edge: ScreenEdge) {
        _layout = AppStorage(wrappedValue: TileKind.defaultLayout, AppSettings.tilesKey(edge))
    }

    private var enabled: [TileKind] { TileKind.decode(layout) }

    var body: some View {
        let on = enabled
        let off = TileKind.allCases.filter { !on.contains($0) }
        VStack(spacing: 6) {
            ForEach(on) { row($0, isOn: true, index: on.firstIndex(of: $0)!, count: on.count) }
            ForEach(off) { row($0, isOn: false, index: 0, count: 0) }
            HStack {
                Spacer()
                Button("Reset") { layout = TileKind.defaultLayout }
                    .buttonStyle(.link)
                    .font(.caption)
            }
        }
    }

    private func row(_ kind: TileKind, isOn: Bool, index: Int, count: Int) -> some View {
        HStack(spacing: 6) {
            Toggle(isOn: Binding(get: { isOn }, set: { set(kind, on: $0) })) {
                Label(kind.title, systemImage: kind.systemImage)
            }
            Spacer()
            if isOn {
                Button { move(index, by: -1) } label: { Image(systemName: "chevron.up") }
                    .disabled(index == 0)
                Button { move(index, by: 1) } label: { Image(systemName: "chevron.down") }
                    .disabled(index == count - 1)
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(isOn ? .primary : .secondary)
    }

    private func set(_ kind: TileKind, on: Bool) {
        var tiles = enabled.filter { $0 != kind }
        if on { tiles.append(kind) }
        layout = TileKind.encode(tiles)
    }

    private func move(_ index: Int, by offset: Int) {
        var tiles = enabled
        let target = index + offset
        guard tiles.indices.contains(index), tiles.indices.contains(target) else { return }
        tiles.swapAt(index, target)
        layout = TileKind.encode(tiles)
    }
}
