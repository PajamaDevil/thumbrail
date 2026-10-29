import SwiftUI

// MARK: Battery

struct BatteryCard: View {
    @ObservedObject var battery: BatteryService

    var body: some View {
        Tile {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(.white.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: battery.level)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: battery.isCharging ? "bolt.fill" : "battery.100")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(battery.hasBattery ? "\(Int((battery.level * 100).rounded()))%" : "No battery")
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                    Text(battery.statusText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var ringColor: Color {
        if battery.isCharging { return .green }
        return battery.level < 0.2 ? .red : .white
    }
}

// MARK: Volume & brightness

struct SlidersRow: View {
    @ObservedObject var volume: VolumeService
    @ObservedObject var brightness: BrightnessService
    let edge: ScreenEdge

    var body: some View {
        HStack(spacing: 12) {
            if edge == .right { brightnessSlider; volumeSlider } else { volumeSlider; brightnessSlider }
        }
    }

    private var volumeSlider: some View {
        VerticalSlider(
            value: Binding(get: { volume.volume }, set: { volume.setVolume($0) }),
            systemImage: volume.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
            tint: .white,
            isEnabled: volume.isAvailable,
            onIconTap: { volume.toggleMute() }
        )
    }

    private var brightnessSlider: some View {
        VerticalSlider(
            value: Binding(get: { brightness.brightness }, set: { brightness.setBrightness($0) }),
            systemImage: "sun.max.fill",
            tint: .yellow,
            isEnabled: brightness.isAvailable,
            onIconTap: nil
        )
    }
}

/// Big fill-style slider: drag anywhere on it, so the thumb doesn't have to land
/// on a tiny knob. Avoids @State so it builds with Command Line Tools alone, which
/// ship without the SwiftUI macro plugin.
struct VerticalSlider: View {
    @Binding var value: Double
    let systemImage: String
    let tint: Color
    let isEnabled: Bool
    let onIconTap: (() -> Void)?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Rectangle().fill(.white.opacity(0.1))
                Rectangle()
                    .fill(tint.opacity(0.9))
                    .frame(height: geo.size.height * CGFloat(value))
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(value > 0.12 ? Color.black.opacity(0.65) : Color.white)
                    .frame(width: geo.size.width, height: 56)
                    .contentShape(Rectangle())
                    .onTapGesture { onIconTap?() }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { drag in
                        value = min(1, max(0, 1 - Double(drag.location.y / geo.size.height)))
                    }
            )
            .opacity(isEnabled ? 1 : 0.35)
            .allowsHitTesting(isEnabled)
        }
    }
}

// MARK: Media

struct MediaControls: View {
    @ObservedObject var media: MediaService

    var body: some View {
        Tile {
            if media.hasAccessibility {
                HStack {
                    button("backward.fill", size: 22) { media.previous() }
                    Spacer()
                    button("playpause.fill", size: 28) { media.playPause() }
                    Spacer()
                    button("forward.fill", size: 22) { media.next() }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Music controls need Accessibility access to send media keys.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Grant access") { media.requestAccessibility() }
                }
            }
        }
    }

    private func button(_ symbol: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .frame(width: 60, height: 56)
                .background(.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Window snapping

struct WindowSnapControls: View {
    @ObservedObject var windows: WindowService

    var body: some View {
        Tile {
            if windows.hasAccessibility {
                HStack(spacing: 8) {
                    button("rectangle.lefthalf.filled", label: "Left") { windows.snap(.left) }
                    button("rectangle.fill", label: "Full") { windows.snap(.full) }
                    button("rectangle.righthalf.filled", label: "Right") { windows.snap(.right) }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Window snapping needs Accessibility access to move windows.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Grant access") { windows.requestAccessibility() }
                }
            }
        }
    }

    private func button(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 22, weight: .semibold))
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Clipboard

struct ClipboardList: View {
    @ObservedObject var clipboard: ClipboardService

    var body: some View {
        Tile {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Clipboard", systemImage: "doc.on.clipboard")
                        .font(.headline)
                    Spacer()
                    if !clipboard.items.isEmpty {
                        Button("Clear") { clipboard.clear() }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                    }
                }

                if clipboard.items.isEmpty {
                    Text("Copied text shows up here.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity, alignment: .top)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(clipboard.items) { item in
                                row(item)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func row(_ item: ClipboardItem) -> some View {
        Button {
            clipboard.copy(item)
        } label: {
            HStack {
                Text(item.text.trimmingCharacters(in: .whitespacesAndNewlines))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if clipboard.justCopiedID == item.id {
                    Image(systemName: "checkmark").foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
