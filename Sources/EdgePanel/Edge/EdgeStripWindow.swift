import AppKit

@MainActor
protocol EdgeGestureDelegate: AnyObject {
    func edgeGestureBegan(edge: ScreenEdge, screen: NSScreen, at point: NSPoint)
    func edgeGestureChanged(at point: NSPoint)
    func edgeGestureEnded(at point: NSPoint, velocityX: CGFloat)
}

/// A thin, invisible, always-on-top window hugging one screen edge. It catches the
/// thumb as it lands on the edge and reports the drag in screen coordinates.
final class EdgeStripWindow: NSPanel {
    private(set) var edge: ScreenEdge = .left
    private(set) var stripView: EdgeStripView!

    convenience init(screen: NSScreen, edge: ScreenEdge, width: CGFloat, zone: CGFloat) {
        let f = screen.frame
        let height = f.height * zone
        let x = edge == .left ? f.minX : f.maxX - width
        let rect = NSRect(x: x, y: f.midY - height / 2, width: width, height: height)

        self.init(contentRect: rect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        self.edge = edge
        stripView = EdgeStripView(frame: NSRect(origin: .zero, size: rect.size), edge: edge, screen: screen)
        contentView = stripView
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        // Fully transparent pixels fall through to the window below, so the view
        // paints a nearly invisible fill and we opt in to mouse events explicitly.
        ignoresMouseEvents = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isMovable = false
        hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class EdgeStripView: NSView {
    weak var delegate: EdgeGestureDelegate?
    let edge: ScreenEdge
    let screen: NSScreen

    private var touchActive = false
    private var samples: [(time: TimeInterval, x: CGFloat)] = []

    init(frame: NSRect, edge: ScreenEdge, screen: NSScreen) {
        self.edge = edge
        self.screen = screen
        super.init(frame: frame)
        // Direct touches are finger-on-display touches. Indirect (trackpad) touches
        // are left alone so normal trackpad use near the edge isn't affected.
        allowedTouchTypes = [.direct]
        wantsRestingTouches = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.01).setFill()
        dirtyRect.fill()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: Pointer path
    // Works with a mouse/trackpad drag from the edge today, and with a touchscreen
    // that delivers taps as pointer events.

    override func mouseDown(with event: NSEvent) {
        guard !touchActive else { return }
        begin(at: NSEvent.mouseLocation, time: event.timestamp)
    }

    override func mouseDragged(with event: NSEvent) {
        guard !touchActive else { return }
        move(to: NSEvent.mouseLocation, time: event.timestamp)
    }

    override func mouseUp(with event: NSEvent) {
        guard !touchActive else { return }
        end(at: NSEvent.mouseLocation, time: event.timestamp)
    }

    // MARK: Direct touch path
    // Used if the system delivers real NSTouch events for the display. Takes
    // priority over the pointer path while a touch is down.

    override func touchesBegan(with event: NSEvent) {
        guard !touchActive, let point = touchPoint(event, phase: .began) else { return }
        touchActive = true
        begin(at: point, time: event.timestamp)
    }

    override func touchesMoved(with event: NSEvent) {
        guard touchActive, let point = touchPoint(event, phase: .moved) else { return }
        move(to: point, time: event.timestamp)
    }

    override func touchesEnded(with event: NSEvent) {
        guard touchActive else { return }
        let point = touchPoint(event, phase: .ended) ?? samples.last.map { NSPoint(x: $0.x, y: 0) } ?? .zero
        touchActive = false
        end(at: point, time: event.timestamp)
    }

    override func touchesCancelled(with event: NSEvent) {
        guard touchActive else { return }
        touchActive = false
        let x = samples.last?.x ?? 0
        end(at: NSPoint(x: x, y: 0), time: event.timestamp)
    }

    private func touchPoint(_ event: NSEvent, phase: NSTouch.Phase) -> NSPoint? {
        guard let touch = event.touches(matching: phase, in: self).first(where: { $0.type == .direct }),
              let window else { return nil }
        let local = touch.location(in: self)
        return window.convertPoint(toScreen: convert(local, to: nil))
    }

    // MARK: Shared gesture tracking

    private func begin(at point: NSPoint, time: TimeInterval) {
        samples = [(time, point.x)]
        delegate?.edgeGestureBegan(edge: edge, screen: screen, at: point)
    }

    private func move(to point: NSPoint, time: TimeInterval) {
        samples.append((time, point.x))
        samples.removeAll { time - $0.time > 0.1 }
        delegate?.edgeGestureChanged(at: point)
    }

    private func end(at point: NSPoint, time: TimeInterval) {
        samples.append((time, point.x))
        samples.removeAll { time - $0.time > 0.1 }
        var velocity: CGFloat = 0
        if let first = samples.first, let last = samples.last, last.time > first.time {
            velocity = (last.x - first.x) / CGFloat(last.time - first.time)
        }
        samples.removeAll()
        delegate?.edgeGestureEnded(at: point, velocityX: velocity)
    }
}
