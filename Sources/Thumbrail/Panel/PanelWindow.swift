import AppKit
import QuartzCore
import SwiftUI

final class PanelState: ObservableObject {
    @Published var edge: ScreenEdge = .right
    var onClose: () -> Void = {}
}

/// The floating, blurred panel that slides in from the edge. It never activates
/// the app, so whatever you were using keeps focus.
final class PanelWindow: NSPanel {
    static let size = NSSize(width: 320, height: 580)
    static let margin: CGFloat = 12
    static let cornerRadius: CGFloat = 28

    private(set) var isOpen = false
    private(set) var progress: CGFloat = 0
    private var edge: ScreenEdge = .right
    private var openFrame: NSRect = .zero
    private var closedFrame: NSRect = .zero

    /// How far the panel moves between fully closed and fully open.
    var travel: CGFloat { abs(openFrame.minX - closedFrame.minX) }

    convenience init<Content: View>(rootView: Content) {
        self.init(contentRect: NSRect(origin: .zero, size: Self.size),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isMovable = false
        hidesOnDeactivate = false
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true

        let blur = NSVisualEffectView(frame: NSRect(origin: .zero, size: Self.size))
        blur.material = .hudWindow
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.maskImage = Self.roundedMask(radius: Self.cornerRadius)

        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = blur.bounds
        hosting.autoresizingMask = [.width, .height]
        blur.addSubview(hosting)
        contentView = blur
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Positions the panel just off the given edge, vertically centered on where
    /// the thumb landed so the controls appear right under it.
    func prepare(edge: ScreenEdge, screen: NSScreen, anchorY: CGFloat) {
        self.edge = edge
        let visible = screen.visibleFrame
        let full = screen.frame
        let size = Self.size
        let y = min(max(anchorY - size.height / 2, visible.minY + Self.margin), visible.maxY - size.height - Self.margin)

        switch edge {
        case .left:
            openFrame = NSRect(x: full.minX + Self.margin, y: y, width: size.width, height: size.height)
            closedFrame = NSRect(x: full.minX - size.width, y: y, width: size.width, height: size.height)
        case .right:
            openFrame = NSRect(x: full.maxX - size.width - Self.margin, y: y, width: size.width, height: size.height)
            closedFrame = NSRect(x: full.maxX, y: y, width: size.width, height: size.height)
        }

        if !isVisible {
            setFrame(closedFrame, display: false)
            alphaValue = 0
            progress = 0
        }
        orderFrontRegardless()
    }

    /// Interactive positioning while the thumb is still down. 0 = closed, 1 = open.
    func setProgress(_ value: CGFloat) {
        // Rubber-band a little past fully open instead of stopping dead.
        let p = value > 1 ? 1 + (value - 1) * 0.15 : max(0, value)
        progress = min(p, 1)
        let x = closedFrame.minX + (openFrame.minX - closedFrame.minX) * p
        setFrameOrigin(NSPoint(x: x, y: openFrame.minY))
        alphaValue = min(1, p * 2.5)
    }

    func animate(open: Bool) {
        isOpen = open
        progress = open ? 1 : 0
        let target = open ? openFrame : closedFrame
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = open ? 0.22 : 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(target, display: true)
            animator().alphaValue = open ? 1 : 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.isOpen else { return }
                self.orderOut(nil)
            }
        })
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}
