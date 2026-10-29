import Foundation
import IOKit.ps

@MainActor
final class BatteryService: ObservableObject {
    @Published private(set) var hasBattery = false
    @Published private(set) var level: Double = 0
    @Published private(set) var isCharging = false
    @Published private(set) var isPluggedIn = false
    /// Minutes, or nil while macOS is still estimating.
    @Published private(set) var minutesRemaining: Int?

    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    var statusText: String {
        guard hasBattery else { return "Desktop power" }
        let time = minutesRemaining.map { m in m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m" }
        if isCharging { return time.map { "Charging · \($0) to full" } ?? "Charging" }
        if isPluggedIn { return "Plugged in" }
        return time.map { "\($0) remaining" } ?? "On battery"
    }

    func refresh() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            hasBattery = false
            return
        }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  desc[kIOPSTypeKey] as? String == kIOPSInternalBatteryType else { continue }

            let current = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            hasBattery = true
            level = max > 0 ? Double(current) / Double(max) : 0
            isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
            isPluggedIn = desc[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue

            let key = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
            if let minutes = desc[key] as? Int, minutes > 0 {
                minutesRemaining = minutes
            } else {
                minutesRemaining = nil
            }
            return
        }
        hasBattery = false
    }
}
