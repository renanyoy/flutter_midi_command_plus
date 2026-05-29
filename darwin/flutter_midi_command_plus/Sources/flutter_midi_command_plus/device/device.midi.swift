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
        var id = maybeId != nil ? String(UInt32(bitPattern: maybeId!), radix: 16) : nil
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
        let type: DeviceType = entity.isNetwork() ? .network : entity == 0 ? .virtual : .native
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
            if entity != 0 {
                entities.insert(entity)
            }
        }
        for s in 0..<sourceCount {
            let source = MIDIGetSource(s)
            var entity: MIDIEntityRef = 0
            var status = MIDIEndpointGetEntity(source, &entity)
            if entity != 0 {
                entities.insert(entity)
            }
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
}
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
