# Edge Panel

A menu bar app for the touchscreen MacBook Pro. Hold the laptop by its left and
right screen edges, slide a thumb in from either edge, and a panel of quick
utilities follows your thumb onto the screen: battery, volume, brightness,
music controls and clipboard history.

## Run it

Requires macOS 14+ and Xcode 15+ (Swift 5.10).

```sh
# Quick dev run (shows in the menu bar as a hand icon)
swift run

# Or build a proper .app (needed for Launch at login)
./Scripts/make-app.sh
open build/EdgePanel.app
```

You can also open `Package.swift` in Xcode and press Run.

### Testing without a touchscreen

- **Mouse/trackpad:** move the pointer all the way to the left or right edge
  of the built-in display (middle part, not the corners), press and hold the
  button, then drag inward. Let go after about a third of the panel is out,
  or flick. Swiping works the same way.
- **Keyboard:** ⌃⌥← opens the left panel and ⌃⌥→ the right one. Press again to close.
- **Menu bar:** the hand icon has "Open left" / "Open right" buttons.
- Close by clicking anywhere outside the panel.

### Permissions

- **Accessibility** is needed for the music buttons (they send the same media
  keys as the keyboard). The panel shows a "Grant access" button. The app is
  ad-hoc signed, so after a rebuild macOS may ask again: remove and re-add it
  in System Settings > Privacy & Security > Accessibility.
- Battery, volume, brightness and clipboard need no permission.

## How it works

```
Sources/EdgePanel
├── App/        EdgePanelApp (menu bar extra), AppSettings, SettingsView
├── Edge/       EdgeStripWindow (invisible edge catcher), EdgeController (gesture → panel)
├── Panel/      PanelWindow (blurred slide-in NSPanel), PanelView + widgets (SwiftUI)
└── Services/   Battery, Volume, Brightness, Media, Clipboard
```

**Edge detection.** macOS has no public edge-swipe or screen-touch API yet, so
the app puts a thin, nearly invisible, non-activating window on each edge of the
built-in display (middle 70% of the height by default, leaving corners free).
It listens two ways:

1. **Pointer events** (mouseDown/Dragged/Up). This works with a mouse today and
   with a touchscreen that turns finger touches into pointer events.
2. **Direct touches** (`NSTouch` with `.direct` type), in case the system
   delivers real touches for the display. These win while a finger is down.
   Trackpad (indirect) touches are ignored so normal trackpad use near the
   edge isn't affected.

When we know exactly how the touchscreen reports input, only
`EdgeStripView` needs to change.

**Gesture.** After 6pt of inward travel, the panel appears and tracks the
thumb. On release it opens if you flicked inward or dragged it more than about a
third of the way. Otherwise it slides back. It is vertically centered on where
your thumb landed.

**Dismiss.** Tap outside, tap the edge again, or tap or drag the grabber bar
back toward the edge.

**Thumb layout.** Controls are at least 44 to 60pt. The two vertical sliders
sit nearest the edge you swiped from, and the layout mirrors for the left
edge. Sliders move relative to where your thumb lands, like Control Center.

## Utilities and the APIs behind them

| Utility    | API | Notes |
|------------|-----|-------|
| Battery    | IOKit `IOPSCopyPowerSourcesInfo` | %, charging, time remaining. Refreshes every 30s and on open. |
| Volume     | CoreAudio `VirtualMainVolume` + `Mute` | Default output device. Tap the speaker icon to mute. |
| Brightness | DisplayServices (private framework, via `dlopen`) | This is what the brightness keys use. Disabled if missing. No App Store. |
| Music      | Synthesized media-key events | Works with any player. Needs Accessibility. No now-playing info yet. |
| Clipboard  | `NSPasteboard` change-count polling | Last 15 text items, in memory only. Skips password-manager (concealed) items. |

## Known limitations / next steps

- The edge strip takes clicks at the very edge pixels in the swipe zone, such
  as a scroll bar flush against the right edge. You can make it narrower
  (4pt) in settings.
- No now-playing title or artwork. On macOS 15.4+ the MediaRemote private
  framework is locked down, so this would need AppleScript per app (Music or
  Spotify) with Automation permission.
- Not sandboxed and uses a private framework, so it can't go on the Mac App Store as is.
- Ideas: customizable tiles, Wi-Fi/Bluetooth/Do Not Disturb toggles, screenshot,
  app shortcuts, haptics when the panel snaps open.
