import CoreMIDI

class MidiTransport : Transport {
    var entity : MIDIEntityRef
    /*
    var inputEndpoint : [MIDIEndpointRef] {
        
    }
     */
    init(client:Client,device:Device,entity:MIDIEntityRef) {
        self.entity = entity
        super.init(client: client, device: device)
        /*
        MIDIInputPortCreateWithBlock(client.clientRef, "MIDI Input", &super.client.midiSetupChannel, { (ref, src, status, data, size) in
            
        }
         */
    }
    override func send(port: Int, data: [UInt8], timestamp: Int?) {}
}
