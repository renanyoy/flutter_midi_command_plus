//
//  transport.virtual.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 28/05/2026.
//

import CoreMIDI

class VirtualTransport: Transport {
    var sourceEndPoint = MIDIEndpointRef()
    var destinationEndPoint = MIDIEndpointRef()

    override init(client: Client, device: Device) {
        super.init(client: client, device: device)
    }

    override func open() {
        let sourceId = Int32(bitPattern: idFrom(name: "\(device.name).source"))
        let destinationId = Int32(bitPattern: idFrom(name: "\(device.name).destination"))
        // source
        MIDISourceCreate(client.clientRef, device.name as CFString, &sourceEndPoint)
        MIDIObjectSetIntegerProperty(sourceEndPoint, kMIDIPropertyUniqueID, sourceId)
        // destination
        MIDIDestinationCreateWithProtocol(
            client.clientRef, device.name as CFString, ._2_0, &destinationEndPoint,
            { list, ref in
                let num = list.pointee.numPackets
                for packet in list.unsafeSequence() {
                    let timestamp: UInt64 = packet.pointee.timeStamp
                    let count = Int(packet.pointee.wordCount)
                    let w = packet.pointee.words
                    let words: [UInt32] = [
                        w.0, w.1, w.2, w.3, w.4, w.5, w.6, w.7, w.8, w.9,
                        w.10, w.11, w.12, w.13, w.14, w.15, w.16, w.17, w.18, w.19,
                        w.20, w.21, w.22, w.23, w.24, w.25, w.26, w.27, w.28, w.29,
                        w.30, w.31, w.32, w.33, w.34, w.35, w.36, w.37, w.38, w.39,
                        w.40, w.41, w.42, w.43, w.44, w.45, w.46, w.47, w.48, w.49,
                        w.50, w.51, w.52, w.53, w.54, w.55, w.56, w.57, w.58, w.59,
                        w.60, w.61, w.62, w.63,
                    ]
                    self.client.sendMidi(
                        deviceId: self.device.id, port: 0, data: Array(words[..<count]),
                        timestamp: timestamp)

                }
            })
        MIDIObjectSetIntegerProperty(
            destinationEndPoint, kMIDIPropertyUniqueID, destinationId)
    }
    override func close() {
        MIDIEndpointDispose(sourceEndPoint)
        MIDIEndpointDispose(destinationEndPoint)
    }
    override func send(port: Int, data: [UInt32], timestamp: UInt64 = 0) {
        var eventList: MIDIEventList = .init()
        var packet = MIDIEventListInit(&eventList, ._2_0)
        MIDIEventListAdd(&eventList, 1024, packet, timestamp, data.count, data)
        MIDIReceivedEventList(sourceEndPoint, &eventList)
    }
}
