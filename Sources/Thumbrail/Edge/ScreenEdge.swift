import AppKit

enum ScreenEdge {
    case left, right
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    var isBuiltIn: Bool {
        guard let id = displayID else { return false }
        return CGDisplayIsBuiltin(id) != 0
    }
}
