//
//  transport.bluetooth.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 28/05/2026.
//

class TransportBluetooth : Transport {
    override init(client: Client, device:Device) {
        super.init(client:client,device:device)
    }
    
    override func open() {}
    override func close() {}
    override func send(port: Int, data: [UInt32], timestamp: UInt64 = 0) {}
}
