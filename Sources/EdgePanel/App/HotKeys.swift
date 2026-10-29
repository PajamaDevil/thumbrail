import Carbon.HIToolbox
import Foundation

/// System-wide shortcuts for testing without a touchscreen:
/// ⌃⌥← opens the left panel, ⌃⌥→ the right one. Carbon hot keys need no
/// Accessibility permission, unlike a global keyDown monitor.
@MainActor
final class HotKeys {
    private var refs: [EventHotKeyRef?] = []
    private var handlerRef: EventHandlerRef?
    private let onPress: (ScreenEdge) -> Void

    private static let signature = OSType(0x45444745) // "EDGE"

    init(onPress: @escaping (ScreenEdge) -> Void) {
        self.onPress = onPress

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            let hotKeys = Unmanaged<HotKeys>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated {
                hotKeys.onPress(id.id == 1 ? .left : .right)
            }
            return OSStatus(noErr)
        }, 1, &spec, context, &handlerRef)

        let modifiers = UInt32(controlKey | optionKey)
        for (id, key) in [(UInt32(1), kVK_LeftArrow), (UInt32(2), kVK_RightArrow)] {
            var ref: EventHotKeyRef?
            RegisterEventHotKey(UInt32(key), modifiers, EventHotKeyID(signature: Self.signature, id: id),
                                GetApplicationEventTarget(), 0, &ref)
            refs.append(ref)
        }
    }
}
