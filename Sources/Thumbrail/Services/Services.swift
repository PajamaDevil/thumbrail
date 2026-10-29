import Foundation

@MainActor
final class Services {
    let battery = BatteryService()
    let volume = VolumeService()
    let brightness = BrightnessService()
    let media = MediaService()
    let clipboard = ClipboardService()

    /// Called as the panel appears so values changed elsewhere (keyboard keys,
    /// Control Center) are current.
    func refreshAll() {
        battery.refresh()
        volume.refresh()
        brightness.refresh()
        media.refreshAccessibility()
    }
}
