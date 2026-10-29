import Foundation

@MainActor
final class Services {
    let battery = BatteryService()
    let volume = VolumeService()
    let brightness = BrightnessService()
    let media = MediaService()
    let clipboard = ClipboardService()
    let windows = WindowService()

    /// Called as the panel appears so values changed elsewhere (keyboard keys,
    /// Control Center) are current.
    func refreshAll() {
        battery.refresh()
        volume.refresh()
        brightness.refresh()
        media.refreshAccessibility()
        windows.refreshAccessibility()
    }
}
