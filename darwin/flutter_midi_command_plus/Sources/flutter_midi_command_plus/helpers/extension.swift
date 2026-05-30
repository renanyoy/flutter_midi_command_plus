import CoreMIDI
import Foundation
import os.log

let midiLog = OSLog(subsystem: "com.invisiblewrench.FlutterMidiCommand", category: "MIDI")

extension MIDIObjectRef {
    func stringProperty(_ name: CFString) -> String? {
        var param: Unmanaged<CFString>?
        let err: OSStatus = MIDIObjectGetStringProperty(self, name, &param)
        if err == OSStatus(noErr) {
            return param!.takeRetainedValue() as String
        }
        return nil
    }
    func integerProperty(_ name:CFString) -> Int32? {
        var value = Int32(0)
        let err:OSStatus = MIDIObjectGetIntegerProperty(self, name, &value)
        if err == OSStatus(noErr) {
            return value
        }
        return nil
    }
    
}
extension MIDIEntityRef {
    func isNetwork() -> Bool {
        var list: Unmanaged<CFPropertyList>?
        MIDIObjectGetProperties(self, &list, true)
        if let list = list {
            let dict = list.takeRetainedValue() as! NSDictionary
            if dict["apple.midirtp.session"] != nil {
                return true
            }
        }
        return false
    }
    var inputCount: Int {
        return Int(MIDIEntityGetNumberOfSources(self))
    }
    var outputCount: Int {
        return Int(MIDIEntityGetNumberOfDestinations(self))
    }
}

extension MIDIObjectType {
    func log() {
        switch self {
        case .other:
            os_log("midiObjectType: Other", log: midiLog, type: .debug)
            break
        case .device:
            os_log("midiObjectType: Device", log: midiLog, type: .debug)
            break
        case .entity:
            os_log("midiObjectType: Entity", log: midiLog, type: .debug)
            break
        case .source:
            os_log("midiObjectType: Source", log: midiLog, type: .debug)
            break
        case .destination:
            os_log("midiObjectType: Destination", log: midiLog, type: .debug)
            break
        case .externalDevice:
            os_log("midiObjectType: ExternalDevice", log: midiLog, type: .debug)
            break
        case .externalEntity:
            print("midiObjectType: ExternalEntity")
            os_log("midiObjectType: ExternalEntity", log: midiLog, type: .debug)
            break
        case .externalSource:
            os_log("midiObjectType: ExternalSource", log: midiLog, type: .debug)
            break
        case .externalDestination:
            os_log(
                "midiObjectType: ExternalDestination",
                log: midiLog,
                type: .debug
            )
            break
        @unknown default:
            break
        }
    }
}

extension Data {
    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        Array(unsafeUninitializedCapacity: self.count/MemoryLayout<T>.stride) { (buffer, i) in
            i = copyBytes(to: buffer) / MemoryLayout<T>.stride
        }
    }
}
