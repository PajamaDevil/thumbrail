import AppKit
import CoreGraphics
import Foundation

/// Built-in display brightness via the DisplayServices private framework, which
/// is what the brightness keys use on Apple silicon. There is no public API for
/// this; if the symbols are missing the slider is shown disabled.
@MainActor
final class BrightnessService: ObservableObject {
    @Published private(set) var brightness: Double = 0
    @Published private(set) var isAvailable = false

    private typealias GetBrightness = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightness = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private let getFn: GetBrightness?
    private let setFn: SetBrightness?

    init() {
        let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
        getFn = handle.flatMap { dlsym($0, "DisplayServicesGetBrightness") }.map { unsafeBitCast($0, to: GetBrightness.self) }
        setFn = handle.flatMap { dlsym($0, "DisplayServicesSetBrightness") }.map { unsafeBitCast($0, to: SetBrightness.self) }
        refresh()
    }

    private var display: CGDirectDisplayID {
        NSScreen.screens.first(where: \.isBuiltIn)?.displayID ?? CGMainDisplayID()
    }

    func refresh() {
        guard let getFn else {
            isAvailable = false
            return
        }
        var value = Float(0)
        isAvailable = getFn(display, &value) == 0
        brightness = Double(value)
    }

    func setBrightness(_ newValue: Double) {
        guard let setFn else { return }
        let value = Float(min(1, max(0, newValue)))
        if setFn(display, value) == 0 {
            brightness = Double(value)
        }
    }
}
