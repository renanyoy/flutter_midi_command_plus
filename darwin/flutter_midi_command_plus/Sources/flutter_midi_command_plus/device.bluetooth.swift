
import CoreBluetooth
import Foundation

#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif


class BluetoothDevice: Device {
    var delegate: BluetoothDeviceDelegate?

    init(
        peripheral: CBPeripheral
    ) {
        let id = peripheral.identifier.uuidString;
        let name = peripheral.name ?? "BLE Midi Device \(id)"
        super.init(id: id, type: .ble, name: name, inputs: 1, outputs: 1)
        self.delegate = BluetoothDeviceDelegate(device: self, peripheral: peripheral)
    }

    
    func setupBLE(client:Client) {
        delegate?.setupBLE(client:client)
    }

}


