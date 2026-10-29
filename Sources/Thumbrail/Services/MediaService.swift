import AppKit
import ApplicationServices

/// Play/pause/next/previous by posting the same system media-key events the
/// keyboard sends, so it works with Music, Spotify, browsers, podcasts, etc.
/// Posting events needs Accessibility permission.
@MainActor
final class MediaService: ObservableObject {
    @Published private(set) var hasAccessibility = AXIsProcessTrusted()

    // From IOKit/hidsystem/ev_keymap.h
    private let keyPlay: Int32 = 16
    private let keyNext: Int32 = 17
    private let keyPrevious: Int32 = 18

    func playPause() { post(keyPlay) }
    func next() { post(keyNext) }
    func previous() { post(keyPrevious) }

    func refreshAccessibility() {
        hasAccessibility = AXIsProcessTrusted()
    }

    func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        hasAccessibility = AXIsProcessTrustedWithOptions(options)
    }

    private func post(_ key: Int32) {
        for down in [true, false] {
            let flags = NSEvent.ModifierFlags(rawValue: down ? 0xA00 : 0xB00)
            let data1 = Int((key << 16) | ((down ? 0xA : 0xB) << 8))
            let event = NSEvent.otherEvent(with: .systemDefined,
                                           location: .zero,
                                           modifierFlags: flags,
                                           timestamp: 0,
                                           windowNumber: 0,
                                           context: nil,
                                           subtype: 8,
                                           data1: data1,
                                           data2: -1)
            event?.cgEvent?.post(tap: .cghidEventTap)
        }
    }
}
