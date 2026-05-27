class Transport {
  let client: Client
  let device: Device
  init(client: Client, device:Device) {
    self.client = client
    self.device = device
  }
  func send(port: Int, data: [UInt8], timestamp: Int?) {}
}
