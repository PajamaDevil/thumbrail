import AppKit
import ApplicationServices

/// Moves the frontmost app's focused window to the left half, right half or the
/// whole of its screen through the Accessibility API. The panel never activates
/// Thumbrail, so the frontmost app is still the one you were using.
@MainActor
final class WindowService: ObservableObject {
    enum Snap { case left, right, full }

    @Published private(set) var hasAccessibility = AXIsProcessTrusted()

    func refreshAccessibility() {
        hasAccessibility = AXIsProcessTrusted()
    }

    func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        hasAccessibility = AXIsProcessTrustedWithOptions(options)
    }

    func snap(_ snap: Snap) {
        guard let window = focusedWindow(), let current = frame(of: window) else { return }
        let screen = Self.screen(containing: current)
        let visible = Self.axRect(screen.visibleFrame)

        var target = visible
        switch snap {
        case .left: target.size.width = (visible.width / 2).rounded()
        case .right:
            target.size.width = (visible.width / 2).rounded()
            target.origin.x = visible.maxX - target.width
        case .full: break
        }

        // Size, move, then size again: some apps refuse a size that would push the
        // window off its current screen, and clamp a position that doesn't fit yet.
        set(target.size, on: window)
        set(target.origin, on: window)
        set(target.size, on: window)
    }

    private func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        let element = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    /// The window's frame in Accessibility coordinates (top-left origin of the main display).
    private func frame(of window: AXUIElement) -> CGRect? {
        var position = CGPoint.zero
        var size = CGSize.zero
        guard let positionValue = axValue(kAXPositionAttribute, of: window),
              let sizeValue = axValue(kAXSizeAttribute, of: window),
              AXValueGetValue(positionValue, .cgPoint, &position),
              AXValueGetValue(sizeValue, .cgSize, &size) else { return nil }
        return CGRect(origin: position, size: size)
    }

    private func axValue(_ attribute: String, of window: AXUIElement) -> AXValue? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, attribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (value as! AXValue)
    }

    private func set(_ point: CGPoint, on window: AXUIElement) {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return }
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
    }

    private func set(_ size: CGSize, on window: AXUIElement) {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    }

    /// Converts between AppKit's bottom-left origin and Accessibility's top-left
    /// origin. The conversion is its own inverse.
    private static func axRect(_ rect: CGRect) -> CGRect {
        let mainHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: rect.minX, y: mainHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    private static func screen(containing axFrame: CGRect) -> NSScreen {
        let center = CGPoint(x: axFrame.midX, y: axFrame.midY)
        return NSScreen.screens.first { axRect($0.frame).contains(center) }
            ?? NSScreen.main ?? NSScreen.screens[0]
    }
}
