//
//  scan.devives.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 26/05/2026.
//

import CoreMIDI
import Foundation

////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
extension Device {
    static func from(entity: MIDIEntityRef) -> Device {
        var device : MIDIDeviceRef = 0
        var status = MIDIEntityGetDevice(entity, &device)
        var maybeId = entity.integerProperty(kMIDIPropertyUniqueID)
        var id = maybeId != nil ? "\(maybeId)": nil
        if id == nil {
            let count = MIDIDeviceGetNumberOfEntities(device)
            var index = 0;
            for e in 0..<count {
                let ent = MIDIDeviceGetEntity(device, e)
                if (ent == entity) {
                    index = e
                    break;
                }
            }
            id = "\(device):\(index)"
        }
        let type: DeviceType = entity.isNetwork() ? .network : .native
        let name = entity.stringProperty(kMIDIPropertyName) ?? device.stringProperty(kMIDIPropertyDisplayName) ?? "No name"
        let inputs = entity.inputCount
        let outputs = entity.outputCount
        return Device(id: id!, type: type, name: name, inputs: inputs, outputs: outputs)
    }

    static var entities : Set<MIDIEntityRef> {
        let destinationCount = MIDIGetNumberOfDestinations()
        let sourceCount = MIDIGetNumberOfSources()
        var entities: Set<MIDIEntityRef> = []
        for d in 0..<destinationCount {
            let destination = MIDIGetDestination(d)
            var entity: MIDIEntityRef = 0
            var status = MIDIEndpointGetEntity(destination, &entity)
            if entity == nil {
                continue
            }
            entities.insert(entity)
        }
        for s in 0..<sourceCount {
            let source = MIDIGetSource(s)
            var entity: MIDIEntityRef = 0
            var status = MIDIEndpointGetEntity(source, &entity)
            if entity == nil {
                continue
            }
            entities.insert(entity)
        }
        return entities
    }
            
    static var devices: Set<Device> {
        return Set(entities.map { Device.from(entity: $0) })
    }
    
    var entity:MIDIEntityRef? {
        for e in Device.entities {
            let d = Device.from(entity: e)
            if d.id == id {
                return e
            }
        }
        return nil
    }

    /*
    
    
    
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
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
