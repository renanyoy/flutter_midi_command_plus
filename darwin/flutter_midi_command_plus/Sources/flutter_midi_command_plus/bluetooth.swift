//
//  bluetouth.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 26/05/2026.
//

import CoreBluetooth
import Foundation

#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif

class Bluetooth: NSObject, CBCentralManagerDelegate,
    CBPeripheralDelegate
{
    var client:Client
    var bluetoothStateChannel: FlutterEventChannel?
    var bluetoothStateHandler = StreamHandler()

    var central: CBCentralManager!
    var ongoingConnections = [String: FlutterResult]()
    var devices : Set<BluetoothDevice> = []
    
    var state : String {
        return central.state.name;
    }
    
    func getDevice(byId id: String) -> BluetoothDevice? {
        return devices.first { $0.id == id }
    }

    init(client:Client) {
        self.client = client
        super.init()
    }
     
    
    /*
    
    func toto() {
        
        for periph: CBPeripheral in discoveredDevices {
            let id = periph.identifier.uuidString
            devices.append([
                "name": periph.name ?? "Unknown",
                "id": id,
                "type": "BLE",
                "connected":
                    (connectedDevices.keys.contains(id) ? "true" : "false"),
                "inputs": [["id": 0, "connected": false] as [String: Any]],
                "outputs": [["id": 0, "connected": false] as [String: Any]],
            ])
        }
    
        // ###########
        // CONNECTED BLE DEVICES (which are no longer discoverable)
        // ###########
    
        connectedDevices.forEach({ (key: String, value: ConnectedDevice) in
            if value.type == .ble
                && !discoveredDevices.contains(where: { periph in
                    periph.identifier.uuidString == key
                })
            {
                if let bleDev = value as? ConnectedBLEDevice {
                    devices.append([
                        "name": bleDev.peripheral.name ?? "Unknown",
                        "id": key,
                        "type": "BLE",
                        "connected": "true",
                        "inputs": [
                            ["id": 0, "connected": true] as [String: Any]
                        ],
                        "outputs": [
                            ["id": 0, "connected": true] as [String: Any]
                        ],
                    ])
                }
            }
        })
        
    }
     */

    
    
    func setup(registrar: FlutterPluginRegistrar) {
        #if os(macOS)
            var messenger = registrar.messenger
        #else
            var messenger = registrar.messenger()
        #endif
        bluetoothStateChannel = FlutterEventChannel(
            name:
                "plugins.invisiblewrench.com/flutter_midi_command/bluetooth_central_state",
            binaryMessenger: messenger
        )
        bluetoothStateChannel?.setStreamHandler(bluetoothStateHandler)
        central = CBCentralManager.init(delegate: self, queue: DispatchQueue.global(qos: .userInteractive))
    }

    public func startScan() -> Bool {
        print("\(state)")
        if central.state == CBManagerState.poweredOn {
            print("Start discovery")
            central.stopScan()
            let serviceList = [
                CBUUID(string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700")
            ]
            central.retrieveConnectedPeripherals(withServices: serviceList)
            central.scanForPeripherals(
                withServices: serviceList,
                options: nil
            )
            return true
        }
        return false
    }
    public func stopScan() {
        central.stopScan()
    }
    
    // Central
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("central did update state \(state)")
        DispatchQueue.main.async {
            self.bluetoothStateHandler.send(data: self.state)
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        print("central didDiscover \(peripheral)")
        let device = BluetoothDevice(peripheral: peripheral)
        devices.insert(device)
        client.sendState("deviceAppeared")
    }

    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        print("central did connect \(peripheral)")
        getDevice(byId: peripheral.identifier.uuidString)?.setupBLE(client:client)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        print(
            "central did fail to connect state \(peripheral) \(String(describing: error?.localizedDescription))"
        )
        client.sendState("connectionFailed")
        if let device = getDevice(byId: peripheral.identifier.uuidString) {
            devices.remove(device)
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        print("central didDisconnectPeripheral \(peripheral)")
        client.sendState("deviceDisconnected")
    }
}

extension CBManagerState {
    var name : String {
        return String(describing: self)
    }
}
