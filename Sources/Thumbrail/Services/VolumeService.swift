import AudioToolbox
import CoreAudio
import Foundation

/// Reads and sets the default output device's volume through CoreAudio.
@MainActor
final class VolumeService: ObservableObject {
    @Published private(set) var volume: Double = 0
    @Published private(set) var isMuted = false
    @Published private(set) var isAvailable = false

    init() { refresh() }

    func refresh() {
        guard let device = Self.defaultOutputDevice() else {
            isAvailable = false
            return
        }
        var volumeAddress = Self.address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
        var value = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        isAvailable = AudioObjectGetPropertyData(device, &volumeAddress, 0, nil, &size, &value) == noErr
        volume = Double(value)

        var muteAddress = Self.address(kAudioDevicePropertyMute)
        var muted = UInt32(0)
        size = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(device, &muteAddress, 0, nil, &size, &muted) == noErr {
            isMuted = muted != 0
        }
    }

    func setVolume(_ newValue: Double) {
        guard let device = Self.defaultOutputDevice() else { return }
        var address = Self.address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
        var value = Float32(min(1, max(0, newValue)))
        let status = AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &value)
        if status == noErr {
            volume = Double(value)
            if isMuted && value > 0 { setMuted(false) }
        }
    }

    func toggleMute() { setMuted(!isMuted) }

    private func setMuted(_ muted: Bool) {
        guard let device = Self.defaultOutputDevice() else { return }
        var address = Self.address(kAudioDevicePropertyMute)
        var value = UInt32(muted ? 1 : 0)
        if AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value) == noErr {
            isMuted = muted
        }
    }

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector,
                                   mScope: kAudioDevicePropertyScopeOutput,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    private static func defaultOutputDevice() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        return status == noErr && device != 0 ? device : nil
    }
}
