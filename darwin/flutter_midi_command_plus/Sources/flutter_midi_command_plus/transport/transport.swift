import CoreMIDI

class Transport {
    let client: Client
    let device: Device
    init(client: Client, device:Device) {
        self.client = client
        self.device = device
    }
    
    func open() {}
    func close() {}
    func send(port: Int, data: [UInt8], timestamp: Int?) {}
    
    static from(client: client, device:Device) : Transport {
        if let entity = device.entity {
            return MidiTransport(client:client,device:device,entity: entity)
        }
        return Transport(client:client,device:device)
    }
}
