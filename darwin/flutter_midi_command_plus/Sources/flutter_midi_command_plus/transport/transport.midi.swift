import CoreMIDI

class MidiTransport : Transport {
    // example https://gist.github.com/sonsongithub/6520ac3f537e3e9b7d3f74e576ae70c5
    var entity : MIDIEntityRef
    var inputPort : MIDIPortRef = MIDIPortRef()
    var outputPort : MIDIPortRef = MIDIPortRef()
    init(client:Client,device:Device,entity:MIDIEntityRef) {
        self.entity = entity
        super.init(client: client, device: device)
    }
    override func open() {
        MIDIInputPortCreateWithProtocol(client.clientRef, "midi_command_\(device.id)_input_port" as CFString, ._2_0, &inputPort) { list, ref in
            let port = Int(bitPattern: ref)
            let num = list.pointee.numPackets
            for packet in list.unsafeSequence() {
                
                self.client.sendMidi(deviceId: device.id, port: port, data: packet.data.subdata(in: 0..<Int(packet.length)) ,timestamp: packet.timeStamp)
            }
        }
        for i in 0..<device.inputs {
            let source = MIDIEntityGetSource(entity, i)
            let status = MIDIPortConnectSource(inputPort, source, i)
        }
        MIDIOutputPortCreate(client.clientRef, "midi_command_\(device.id)_output_port" as CFString, &outputPort);
    }
    override func close() {
        for i in 0..<device.inputs {
            let source = MIDIEntityGetSource(entity, i)
            MIDIPortDisconnectSource(inputPort, source)
        }
        MIDIPortDispose(inputPort)
        MIDIPortDispose(outputPort)
    }
    override func send(port: Int, data: [UInt8], timestamp: UInt64 = 0) {
        let destination = MIDIEntityGetDestination(entity, i)
        var eventList: MIDIEventList = .init()
        var packet = MIDIEventListInit(&eventList, ._2_0)
        MIDIEventListAdd(&eventList, 1024, packet, timestamp, data.count/2, data)
        MIDISendEventList(outputPort, destination, &eventList)
    }
}
