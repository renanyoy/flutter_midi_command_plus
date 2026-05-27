//
//  midi.client.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 26/05/2026.
//

import CoreMIDI
import Foundation
import os.log

#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif

class Client {
    lazy var bluetooth: Bluetooth = Bluetooth(client: self)
    var clientRef: MIDIClientRef = 0
    var midiRXChannel: FlutterEventChannel?
    var rxStreamHandler = StreamHandler()
    var midiSetupChannel: FlutterEventChannel?
    var setupStreamHandler = StreamHandler()

    #if os(iOS)
        // Network Session
        var session: MIDINetworkSession?
    #endif

    var devices: Set<Device> {
        return Device.devices.union(bluetooth.devices)
    }
    var transports: [String:Transport] = [:]

    func getDevice<T: Device>(byId id: String) -> T? {
        let d = devices.first { $0.id == id }
        return d as? T
    }

    init() {
    }

    deinit {
        MIDIClientDispose(clientRef)
    }

    func setup(registrar: FlutterPluginRegistrar) {
        #if os(macOS)
            var messenger = registrar.messenger
        #else
            var messenger = registrar.messenger()
        #endif

        midiRXChannel = FlutterEventChannel(
            name:
                "plugins.aestesis.org/flutter_midi_command/rx_channel",
            binaryMessenger: messenger
        )
        midiRXChannel?.setStreamHandler(rxStreamHandler)

        midiSetupChannel = FlutterEventChannel(
            name:
                "plugins.aestesis.org/flutter_midi_command/setup_channel",
            binaryMessenger: messenger
        )
        midiSetupChannel?.setStreamHandler(setupStreamHandler)

        bluetooth.setup(registrar: registrar)

        MIDIClientCreateWithBlock(
            "plugins.aestesis.org.FlutterMidiCommand" as CFString,
            &clientRef
        ) { (notification) in
            self.handleMIDINotification(notification)
        }

        #if os(iOS)
            session = MIDINetworkSession.default()
            session?.connectionPolicy = MIDINetworkConnectionPolicy.anyone
        #endif
    }

    func sendState(_ data: Any) {
        DispatchQueue.main.async {
            self.setupStreamHandler.send(data: data)
        }
    }
    func sendMidi(deviceId: String, port: Int, data: [UInt8], timestamp: Int?) {
        let d = Data(bytes: data, count: Int(data.count))
        DispatchQueue.main.async {
            self.rxStreamHandler.send(data: [
                "deviceId": deviceId, "data": data, "timestamp": timestamp,
            ])
        }
    }

    func isConnected(deviceId:String) -> Bool {
        return transports.keys.contains(deviceId)
    }
    
    func connectDevice(deviceId: String) -> Bool {
        // TODO:
        return false
    }

    func disconnectDevice(deviceId: String) -> Bool {
        // TODO:
        return false
    }

    func handleMIDINotification(
        _ midiNotification: UnsafePointer<MIDINotification>
    ) {
        print("\ngot a MIDINotification!")

        let notification = midiNotification.pointee
        print(
            "MIDI Notify, messageId= \(notification.messageID) \(notification.messageSize)"
        )

        sendState("\(notification.messageID)")

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

    // Create an own virtual device appearing in other apps.
    // Other apps can use that device to send and receive MIDI to and from this app.
    /*
        func findOrCreateOwnVirtualDevice(name: String) -> ConnectedOwnVirtualDevice {
            let existingDevice = ownVirtualDevices.first(where: { device in
                device.name == name
            })
    
            let result =
                existingDevice
                ?? ConnectedOwnVirtualDevice(
                    name: name,
                    streamHandler: rxStreamHandler,
                    client: midiClient
                )
            if existingDevice == nil {
                ownVirtualDevices.insert(result)
            }
    
            return result
        }
    */

    /*
        func removeOwnVirtualDevice(name: String) {
            let existingDevice = ownVirtualDevices.first(where: { device in
                device.name == name
            })
    
            if let existingDevice = existingDevice {
                existingDevice.close()
                ownVirtualDevices.remove(existingDevice)
            }
        }
    
        // Check if an endpoint is an own virtual destination or source
        func isOwnVirtualEndpoint(endpoint: MIDIEndpointRef) -> Bool {
            return ownVirtualDevices.contains { device in
                device.virtualSourceEndpoint == endpoint
                    || device.virtualDestinationEndpoint == endpoint
            }
        }
    */
    // BLE

    #if os(iOS)
        /// MIDI Network Session
        @objc func midiNetworkChanged(notification: NSNotification) {
            print("\(#function)")
            print("\(notification)")
            if let session = notification.object as? MIDINetworkSession {
                print("session \(session)")
                for con in session.connections() {
                    print("con \(con)")
                }
                print("isEnabled \(session.isEnabled)")
                print("sourceEndpoint \(session.sourceEndpoint())")
                print("destinationEndpoint \(session.destinationEndpoint())")
                print("networkName \(session.networkName)")
                print("localName \(session.localName)")

                //            if let name = getDeviceName(session.sourceEndpoint()) {
                //                print("source name \(name)")
                //            }
                //
                //            if let name = getDeviceName(session.destinationEndpoint()) {
                //                print("destination name \(name)")
                //            }
            }
            sendState("\(#function) \(notification)")
        }

        @objc func midiNetworkContactsChanged(notification: NSNotification) {
            print("\(#function)")
            print("\(notification)")
            if let session = notification.object as? MIDINetworkSession {
                print("session \(session)")
                for con in session.contacts() {
                    print("contact \(con)")
                }
            }
            sendState("\(#function) \(notification)")
        }
    #endif

}
