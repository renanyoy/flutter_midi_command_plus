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
    func send(port: Int, data: [UInt32], timestamp: UInt64 = 0) {}
    
    static func from(client:Client, device:Device) -> Transport {
        if device.type == .virtual {
            return VirtualTransport(client: client, device: device)
        }
        if let entity = device.entity {
            return MidiTransport(client:client,device:device,entity:entity)
        }
        return Transport(client:client,device:device)
    }
}
