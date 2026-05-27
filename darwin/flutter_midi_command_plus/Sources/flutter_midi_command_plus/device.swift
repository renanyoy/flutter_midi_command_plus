//
//  device.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 25/05/2026.
//

import CoreMIDI
import Foundation

////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
enum DeviceType {
    case native, virtual, ownVirtual, ble, network
    func toString() -> String {
        switch self {
        case .native:
            return "native"
        case .virtual:
            return "virtual"
        case .ownVirtual:
            return "ownVirtual"
        case .ble:
            return "ble"
        case .network:
            return "network"
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
class Device: Hashable {
    internal init(
        id: String, type: DeviceType, name: String, inputs: Int, outputs: Int
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.inputs = inputs
        self.outputs = outputs
    }
    var id: String
    var type: DeviceType
    var name: String
    var inputs: Int
    var outputs: Int
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type.toString(),
            "name": name,
            "inputs": inputs,
            "outputs": outputs,
        ]
    }
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
class ConnectedDevice: Device {
    var streamHandler: StreamHandler? = nil
    func send(port: UInt64, bytes: [UInt8], timestamp: UInt64?) {}
    func open(streamHandler: StreamHandler) {
        self.streamHandler = streamHandler
    }
    func close() {
    }
}
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
