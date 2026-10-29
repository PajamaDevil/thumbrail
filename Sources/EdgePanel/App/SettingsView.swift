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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edge Panel").font(.headline)

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

            Button("Quit Edge Panel") { NSApp.terminate(nil) }
        }
        .padding(16)
        .frame(width: 300)
    }
}
