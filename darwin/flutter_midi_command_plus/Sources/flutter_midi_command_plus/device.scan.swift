//
//  scan.devives.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 26/05/2026.
//

import CoreMIDI
import Foundation

extension Device {
    static func from(ref: MIDIEntityRef) -> Device {
        let id = ref.property(kMIDIPropertyUniqueID)!
        let type: DeviceType = ref.isNetwork() ? .network : .native
        let name = ref.property(kMIDIPropertyDisplayName)!
        let inputs = ref.inputCount
        let outputs = ref.outputCount
        return Device(id: id, type: type, name: name, inputs: inputs, outputs: outputs)
    }

    static func getDevices() -> [Device] {
        var devices: [MIDIEntityRef: Device] = [:]
        let destinationCount = MIDIGetNumberOfDestinations()
        let sourceCount = MIDIGetNumberOfSources()
        var entities: Set<MIDIEntityRef> = []
        var noEntityDestination: [MIDIEndpointRef] = []
        var noEntitySource: [MIDIEndpointRef] = []
        for d in 0..<destinationCount {
            let destination = MIDIGetDestination(d)
            var entity: MIDIEntityRef = 0
            var status = MIDIEndpointGetEntity(destination, &entity)
            if entity == nil {
                noEntityDestination.append(destination)
                continue
            }
            entities.insert(entity)
        }
        for s in 0..<sourceCount {
            let source = MIDIGetSource(s)
            var entity: MIDIEntityRef = 0
            var status = MIDIEndpointGetEntity(source, &entity)
            if entity == nil {
                noEntitySource.append(source)
                continue
            }
            entities.insert(entity)
        }
        return entities.map { Device.from(ref:$0) }
    }
    /*
     
    static func getDevices() -> [[String: Any]] {
        var devices: [[String: Any]] = []
    
        // ######
        // Native
        // ######
    
        var nativeDevices = [MIDIEntityRef: [String: Any]]()
    
        let destinationCount = MIDIGetNumberOfDestinations()
        for d in 0..<destinationCount {
            let destination = MIDIGetDestination(d)
            //            print("dest \(destination) \(FlutterMidiCommandPlusPlugin.getMIDIProperty(kMIDIPropertyName, fromObject: destination))")
    
            if isVirtualEndpoint(endpoint: destination) {
                continue
            }
    
            var entity: MIDIEntityRef = 0
            var status = MIDIEndpointGetEntity(destination, &entity)
            if status != noErr {
                print("Error \(status) while calling MIDIEndpointGetEntity")
            }
    
            let isNetwork = FlutterMidiCommandPlusPlugin.isNetwork(
                device: entity
            )
    
            var device: MIDIDeviceRef = 0
            status = MIDIEntityGetDevice(entity, &device)
            if status != noErr {
                print("Error \(status) while calling MIDIEntityGetDevice")
            }
    
            let name = displayName(endpoint: destination)
    
            let entityCount = MIDIDeviceGetNumberOfEntities(device)
            //            print("entityCount \(entityCount)")
    
            var entityIndex = 0
            for e in 0..<entityCount {
                let ent = MIDIDeviceGetEntity(device, e)
                //                print("ent \(ent)")
                if ent == entity {
                    entityIndex = e
                }
            }
            //            print("entityIndex \(entityIndex)")
            let deviceId = "\(device):\(entityIndex)"
    
            let entityDestinationCount = MIDIEntityGetNumberOfDestinations(
                entity
            )
            //            print("entiry dest count \(entityDestinationCount)")
    
            nativeDevices[entity] = [
                "name": name,
                "id": deviceId,
                "type": isNetwork ? "network" : "native",
                "connected":
                    (connectedDevices.keys.contains(deviceId)
                     ? "true" : "false"),
                "outputs": createPortDict(count: entityDestinationCount),
            ]
        }
    
        let sourceCount = MIDIGetNumberOfSources()
        for s in 0..<sourceCount {
            let source = MIDIGetSource(s)
            //            print("src \(source) \(FlutterMidiCommandPlusPlugin.getMIDIProperty(kMIDIPropertyName, fromObject: source))")
    
            if isVirtualEndpoint(endpoint: source) {
                continue
            }
    
            var entity: MIDIEntityRef = 0
            var status = MIDIEndpointGetEntity(source, &entity)
            if status != noErr {
                print("Error \(status) while calling MIDIEndpointGetEntity")
            }
            let isNetwork = FlutterMidiCommandPlusPlugin.isNetwork(
                device: entity
            )
            let name = displayName(endpoint: source)
    
            var device: MIDIDeviceRef = 0
            status = MIDIEntityGetDevice(entity, &device)
            if status != noErr {
                print("Error \(status) while calling MIDIEntityGetDevice")
            }
    
            let entityCount = MIDIDeviceGetNumberOfEntities(device)
            //            print("entityCount \(entityCount)")
    
            var entityIndex = 0
            for e in 0..<entityCount {
                let ent = MIDIDeviceGetEntity(device, e)
                //                print("ent \(ent)")
                if ent == entity {
                    entityIndex = e
                }
            }
            //            print("entityIndex \(entityIndex)")
    
            let deviceId = "\(device):\(entityIndex)"
    
            let entitySourceCount = MIDIEntityGetNumberOfSources(entity)
            //            print("entiry source count \(entitySourceCount)")
    
            if var deviceDict = nativeDevices[entity] {
                //                print("add inputs to dict")
                deviceDict["inputs"] = createPortDict(count: entitySourceCount)
                //                print(type(of: createPortDict(count: entitySourceCount)))
                nativeDevices[entity] = deviceDict
            } else {
                //                print("create inputs dict")
                nativeDevices[entity] = [
                    "name": name,
                    "id": deviceId,
                    "type": isNetwork ? "network" : "native",
                    "connected":
                        (connectedDevices.keys.contains(deviceId)
                         ? "true" : "false"),
                    "inputs": createPortDict(count: entitySourceCount),
                ]
            }
        }
    
        devices.append(contentsOf: nativeDevices.values)
    
        // ######
        // BLE
        // ######
    
        for periph: CBPeripheral in discoveredDevices {
            let id = periph.identifier.uuidString
            devices.append([
                "name": periph.name ?? "Unknown",
                "id": id,
                "type": "BLE",
                "connected":
                    (connectedDevices.keys.contains(id) ? "true" : "false"),
                "inputs": [["id": 0, "connected": false] as [String: Any]],
                "outputs": [["id": 0, "connected": false] as [String: Any]],
            ])
        }
    
        // ###########
        // CONNECTED BLE DEVICES (which are no longer discoverable)
        // ###########
    
        connectedDevices.forEach({ (key: String, value: ConnectedDevice) in
            if value.type == .ble
                && !discoveredDevices.contains(where: { periph in
                    periph.identifier.uuidString == key
                })
            {
                if let bleDev = value as? ConnectedBLEDevice {
                    devices.append([
                        "name": bleDev.peripheral.name ?? "Unknown",
                        "id": key,
                        "type": "BLE",
                        "connected": "true",
                        "inputs": [
                            ["id": 0, "connected": true] as [String: Any]
                        ],
                        "outputs": [
                            ["id": 0, "connected": true] as [String: Any]
                        ],
                    ])
                }
            }
        })
    
        // #######
        // VIRTUAL
        // #######
    
        var virtualDevices = [MIDIEntityRef: [String: Any]]()
    
        for d in 0..<destinationCount {
            let destination = MIDIGetDestination(d)
    
            if !isVirtualEndpoint(endpoint: destination) {
                continue
            }
    
            if isOwnVirtualEndpoint(endpoint: destination) {
                continue
            }
    
            let displayName = FlutterMidiCommandPlusPlugin.getMIDIProperty(
                kMIDIPropertyDisplayName,
                fromObject: destination
            )
            let id = stringToId(str: displayName)  // Will cause conflicts when multiple virtual endpoints with the same name exist
    
            virtualDevices[id] = [
                "name": displayName,
                "id": "\(destination)",
                "type": "virtual",
                "connected":
                    (connectedDevices.keys.contains(String(destination))
                     ? "true" : "false"),
                "outputs": createPortDict(count: 1),
            ]
        }
    
        for s in 0..<sourceCount {
            let source = MIDIGetSource(s)
    
            if !isVirtualEndpoint(endpoint: source) {
                continue
            }
    
            if isOwnVirtualEndpoint(endpoint: source) {
                continue
            }
    
            let displayName = FlutterMidiCommandPlusPlugin.getMIDIProperty(
                kMIDIPropertyDisplayName,
                fromObject: source
            )
            let id = stringToId(str: displayName)  // Will cause conflicts when multiple virtual endpoints with the same name exist
    
            if var deviceDict = virtualDevices[id] {
                deviceDict["inputs"] = createPortDict(count: 1)
                let destination = deviceDict["id"] as? String ?? ""
                let id2 = "\(destination):\(source)"
                deviceDict["id"] = id2
                deviceDict["connected"] =
                (connectedDevices.keys.contains(id2) ? "true" : "false")
                virtualDevices[id] = deviceDict
    
            } else {
                //                print("create inputs dict")
                let id2 = ":\(source)"
                virtualDevices[id] = [
                    "name": displayName,
                    "id": id2,
                    "type": "virtual",
                    "connected":
                        (connectedDevices.keys.contains(id2)
                         ? "true" : "false"),
                    "inputs": createPortDict(count: 1),
                ]
            }
        }
    
        devices.append(contentsOf: virtualDevices.values)
    
        // ###########
        // OWN VIRTUAL
        // ###########
    
        var ownVirtualDevices = [MIDIEntityRef: [String: Any]]()
    
        for ownVirtualDevice in self.ownVirtualDevices {
            let displayName = ownVirtualDevice.deviceName
            let id = stringToId(str: displayName)
    
            ownVirtualDevices[id] = [
                "name": displayName,
                "id": "\(id)",
                "type": "own-virtual",
                "connected":
                    (connectedDevices.keys.contains(String(id))
                     ? "true" : "false"),
                "outputs": createPortDict(count: 1),
                "inputs": createPortDict(count: 1),
            ]
        }
    
        devices.append(contentsOf: ownVirtualDevices.values)
    
        return devices
    }
    */
}
