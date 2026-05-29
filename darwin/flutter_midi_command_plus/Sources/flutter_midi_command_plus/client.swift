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

    var vdevices: Set<Device> = []
    var devices: Set<Device> {
        return Device.devices.union(bluetooth.devices).union(vdevices)
    }
    var transports: [String: Transport] = [:]

    func getDevice<T: Device>(byId id: String) -> T? {
        let d = devices.first { $0.id == id }
        return d as? T
    }

    init() {
    }

    deinit {
        for transport in transports.values {
            transport.close()
        }
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
    func sendMidi(deviceId: String, port: Int, data: [UInt32], timestamp: UInt64?) {
        let d = Data(bytes: data, count: Int(data.count))
        DispatchQueue.main.async {
            self.rxStreamHandler.send(data: [
                "deviceId": deviceId, "data": data, "timestamp": timestamp,
            ])
        }
    }

    func isConnected(deviceId: String) -> Bool {
        return transports.keys.contains(deviceId)
    }

    func connectDevice(deviceId: String) -> Bool {
        if transports.keys.contains(deviceId) {
            return true
        }
        if let device = getDevice(byId: deviceId) {
            let transport = Transport.from(client: self, device: device)
            transport.open()
            transports[deviceId] = transport
            return true
        }
        return false
    }

    func disconnectDevice(deviceId: String) {
        if let transport = transports[deviceId] {
            transports.removeValue(forKey: deviceId)
            transport.close()
        }
    }

    func addVirtualDevice(name: String) -> Device {
        var n: Int = 1
        var nm = name
        while true {
            if vdevices.first { $0.name == nm } == nil {
                break
            }
            n += 1
            nm = "\(name) #\(n)"
        }
        let id = hexIdFrom(name:nm)
        let device = Device(id: id, type: .virtual, name: nm, inputs: 1, outputs: 1)
        vdevices.insert(device)
        let transport = Transport.from(client: self, device: device)
        transport.open()
        transports[device.id] = transport
        return device
    }

    func removeVirtualDevice(deviceId: String) {
        if let device = vdevices.first { $0.id == deviceId } {
            vdevices.remove(device)
            if let transport = transports[deviceId] {
                transports.removeValue(forKey: deviceId)
                transport.close()
            }
        }
    }

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

}
