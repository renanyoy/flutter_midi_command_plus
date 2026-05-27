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
        MIDIInputPortCreateWithProtocol(client, "midi_command_\(device.id)_input_\(i)" as CFString, ._2_0, &inputPort[i]) { list, ref in
            let port = ref as Int
            let num = list.pointee.numPackets
            for packet:MIDIPacket in list.unsafeSequence() {
                client.sendMidi(deviceId: device.id, port: port, data: packet.data.subdata(in: 0..<Int(packet.length)) ,timestamp: packet.timeStamp)
            }
        }
        for i in 0..<device.inputs {
            let source = MIDIEntityGetSource(entity, i)
            let status = MIDIPortConnectSource(inputPort, source, i)
        }
        MIDIOutputPortCreate(client, "midi_command_\(device_id)_output_\(i)" as CFString, &outputPort);
        for i in 0..<device.outputs {
            let destination = MIDIEntityGetDestination(entity, i)
        }
        
        
    }
    override func close() {
        // TODO: close all
    }
    override func send(port: Int, data: [UInt8], timestamp: Int?) {
        let destination = MIDIEntityGetDestination(entity, i)
        var eventList: MIDIEventList = .init()
        var packet = MIDIEventListInit(&eventList, ._2_0)
        MIDIEventListAdd(&eventList, 1024, packet, 0, data.count, data)
        MIDISendEventList(outputPort, destination, &eventList)
    }
}
