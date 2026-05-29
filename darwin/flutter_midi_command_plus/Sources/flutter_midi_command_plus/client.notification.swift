import CoreMIDI
import Foundation
import os.log

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

extension Client {
    func handleMIDINotification(
        _ midiNotification: UnsafePointer<MIDINotification>
    ) {
        print("\ngot a MIDINotification!")
        
        let notification = midiNotification.pointee
        print(
            "MIDI Notify, messageId= \(notification.messageID) \(notification.messageSize)"
        )
        
        //MIDINotificationMessageID
        sendState(notification.messageID.description)
        
        switch notification.messageID {
            
            // Some aspect of the current MIDISetup has changed.  No data.  Should ignore this  message if messages 2-6 are handled.
        case .msgSetupChanged:
            print("MIDI setup changed")
            let ptr = UnsafeMutablePointer<MIDINotification>(
                mutating: midiNotification
            )
            //            let ptr = UnsafeMutablePointer<MIDINotification>(midiNotification)
            let m = ptr.pointee
            print(m)
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            break
            
            // A device, entity or endpoint was added. Structure is MIDIObjectAddRemoveNotification.
        case .msgObjectAdded:
            
            print("added")
            //            let ptr = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(midiNotification)
            
            midiNotification.withMemoryRebound(
                to: MIDIObjectAddRemoveNotification.self,
                capacity: 1
            ) {
                let m = $0.pointee
                print(m)
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("child \(m.child)")
                print("child type \(m.childType)")
                m.childType.log()
                print("parent \(m.parent)")
                print("parentType \(m.parentType)")
                m.parentType.log()
                //                print("childName \(String(describing: getDisplayName(m.child)))")
            }
            
            break
            
            // A device, entity or endpoint was removed. Structure is MIDIObjectAddRemoveNotification.
        case .msgObjectRemoved:
            print("kMIDIMsgObjectRemoved")
            //            let ptr = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(midiNotification)
            midiNotification.withMemoryRebound(
                to: MIDIObjectAddRemoveNotification.self,
                capacity: 1
            ) {
                
                let m = $0.pointee
                print(m)
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("child \(m.child)")
                print("child type \(m.childType)")
                print("parent \(m.parent)")
                print("parentType \(m.parentType)")
                
                //                print("childName \(String(describing: getDisplayName(m.child)))")
            }
            break
            
            // An object's property was changed. Structure is MIDIObjectPropertyChangeNotification.
        case .msgPropertyChanged:
            print("kMIDIMsgPropertyChanged")
            midiNotification.withMemoryRebound(
                to: MIDIObjectPropertyChangeNotification.self,
                capacity: 1
            ) {
                
                let m = $0.pointee
                print(m)
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("object \(m.object)")
                print("objectType  \(m.objectType)")
                print("propertyName  \(m.propertyName)")
                print("propertyName  \(m.propertyName.takeUnretainedValue())")
                
                if m.propertyName.takeUnretainedValue() as String
                    == "apple.midirtp.session"
                {
                    print("connected")
                }
            }
            
            break
            
            //     A persistent MIDI Thru connection wasor destroyed.  No data.
        case .msgThruConnectionsChanged:
            print("MIDI thru connections changed.")
            break
            
            //A persistent MIDI Thru connection was created or destroyed.  No data.
        case .msgSerialPortOwnerChanged:
            print("MIDI serial port owner changed.")
            break
            
        case .msgIOError:
            print("MIDI I/O error.")
            
            //let ptr = UnsafeMutablePointer<MIDIIOErrorNotification>(midiNotification)
            midiNotification.withMemoryRebound(
                to: MIDIIOErrorNotification.self,
                capacity: 1
            ) {
                let m = $0.pointee
                print(m)
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("driverDevice \(m.driverDevice)")
                print("errorCode \(m.errorCode)")
            }
            break
        @unknown default:
            break
        }
    }
}

extension MIDINotificationMessageID {
    var description: String {
        switch self {
        case .msgSetupChanged:
            return "setupChanged"
        case .msgObjectAdded:
            return "objectAdded"
        case .msgObjectRemoved:
            return "objectRemoved"
        case .msgPropertyChanged:
            return "propertyChanged"
        case .msgThruConnectionsChanged:
            return "thruConnectionsChanged"
        case .msgSerialPortOwnerChanged:
            return "serialPortOwnerChanged"
        case .msgIOError:
            return "ioError"
        @unknown default:
            return "other (rawValue: \(rawValue))"
        }
    }
}

