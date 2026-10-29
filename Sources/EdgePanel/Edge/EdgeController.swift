import AppKit
import SwiftUI

/// Owns the edge strips and the panel, and turns an edge drag into the panel
/// following the thumb, then snapping open or closed on release.
@MainActor
final class EdgeController: EdgeGestureDelegate {
    let services = Services()

    private let panelState = PanelState()
    private lazy var panel = PanelWindow(rootView: PanelView(state: panelState, services: services))
    private var strips: [EdgeStripWindow] = []
    private var observers: [NSObjectProtocol] = []
    private var outsideClickMonitor: Any?
    private var rebuildWork: DispatchWorkItem?

    private var gestureStart: NSPoint?
    private var gestureEdge: ScreenEdge = .right
    private var gestureScreen: NSScreen?
    private var gestureEngaged = false

    /// Distance the thumb travels inward before the panel starts to follow.
    private let engageDistance: CGFloat = 6

    init() {
        panelState.onClose = { [weak self] in self?.close() }
    }

    func start() {
        AppSettings.registerDefaults()
        rebuildStrips()

        let center = NotificationCenter.default
        for name in [NSApplication.didChangeScreenParametersNotification, UserDefaults.didChangeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.scheduleRebuild() }
            })
        }
    }

    /// Opens the panel without a gesture (used by the menu bar buttons).
    func toggle(edge: ScreenEdge) {
        if panel.isOpen {
            close()
            return
        }
        guard let screen = targetScreens().first ?? NSScreen.main else { return }
        prepare(edge: edge, screen: screen, anchorY: screen.frame.midY)
        open()
    }

    // MARK: Strips

    private func scheduleRebuild() {
        rebuildWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.rebuildStrips() }
        }
        rebuildWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }

    private func rebuildStrips() {
        strips.forEach { $0.orderOut(nil) }
        strips.removeAll()

        for screen in targetScreens() {
            for edge in AppSettings.enabledEdges {
                let strip = EdgeStripWindow(screen: screen, edge: edge, width: AppSettings.stripWidth, zone: AppSettings.activeZone)
                strip.stripView.delegate = self
                strip.orderFrontRegardless()
                strips.append(strip)
            }
        }
    }

    /// The touchscreen is the built-in display, so by default only that one gets strips.
    private func targetScreens() -> [NSScreen] {
        if AppSettings.allDisplays { return NSScreen.screens }
        if let builtIn = NSScreen.screens.first(where: \.isBuiltIn) { return [builtIn] }
        return NSScreen.main.map { [$0] } ?? []
    }

    // MARK: EdgeGestureDelegate

    func edgeGestureBegan(edge: ScreenEdge, screen: NSScreen, at point: NSPoint) {
        if panel.isOpen {
            // Touching the edge again while open dismisses.
            close()
            gestureStart = nil
            return
        }
        gestureStart = point
        gestureEdge = edge
        gestureScreen = screen
        gestureEngaged = false
    }

    func edgeGestureChanged(at point: NSPoint) {
        guard let start = gestureStart, let screen = gestureScreen else { return }
        let inward = inwardDistance(from: start, to: point)
        if !gestureEngaged {
            guard inward > engageDistance else { return }
            gestureEngaged = true
            prepare(edge: gestureEdge, screen: screen, anchorY: start.y)
        }
        panel.setProgress((inward - engageDistance) / panel.travel)
    }

    func edgeGestureEnded(at point: NSPoint, velocityX: CGFloat) {
        defer { gestureStart = nil; gestureEngaged = false }
        guard gestureEngaged else { return }
        let inwardVelocity = gestureEdge == .left ? velocityX : -velocityX
        let flicked = inwardVelocity > 500
        let draggedFarEnough = panel.progress > 0.35 && inwardVelocity > -300
        if flicked || draggedFarEnough {
            open()
        } else {
            close()
        }
    }

    // MARK: Panel

    private func inwardDistance(from start: NSPoint, to point: NSPoint) -> CGFloat {
        gestureEdge == .left ? point.x - start.x : start.x - point.x
    }

    private func prepare(edge: ScreenEdge, screen: NSScreen, anchorY: CGFloat) {
        panelState.edge = edge
        services.refreshAll()
        panel.prepare(edge: edge, screen: screen, anchorY: anchorY)
    }

    private func open() {
        panel.animate(open: true)
        installOutsideClickMonitor()
    }

    private func close() {
        panel.animate(open: false)
        removeOutsideClickMonitor()
    }

    /// Clicks/taps in other apps close the panel. Events in our own windows don't
    /// reach a global monitor, so taps inside the panel are unaffected.
    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
    }

    private func removeOutsideClickMonitor() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
}
