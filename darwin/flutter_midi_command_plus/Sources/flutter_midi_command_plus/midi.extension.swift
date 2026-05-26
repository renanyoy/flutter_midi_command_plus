import CoreMIDI
import Foundation

extension MIDIObjectRef {
    func property(_ name: CFString) -> String? {
        var param: Unmanaged<CFString>?
        let err: OSStatus = MIDIObjectGetStringProperty(self, name, &param)
        if err == OSStatus(noErr) {
            return param!.takeRetainedValue() as String
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
