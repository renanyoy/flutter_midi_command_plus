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
    var client: Client
    var bluetoothStateChannel: FlutterEventChannel?
    var bluetoothStateHandler = StreamHandler()

    var central: CBCentralManager!
    var ongoingConnections = [String: FlutterResult]()
    var devices: Set<BluetoothDevice> = []

    var state: String {
        return central.state.name
    }

    func getDevice(byId id: String) -> BluetoothDevice? {
        return devices.first { $0.id == id }
    }

    init(client: Client) {
        self.client = client
        super.init()
    }

    func setup(registrar: FlutterPluginRegistrar) {
        #if os(macOS)
            var messenger = registrar.messenger
        #else
            var messenger = registrar.messenger()
        #endif
        bluetoothStateChannel = FlutterEventChannel(
            name:
                "plugins.aestesis.org/flutter_midi_command/bluetooth_central_state",
            binaryMessenger: messenger
        )
        bluetoothStateChannel?.setStreamHandler(bluetoothStateHandler)
        central = CBCentralManager.init(
            delegate: self, queue: DispatchQueue.global(qos: .userInteractive))
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
        print("central did update state \(central.state.name)")
        DispatchQueue.main.async {
            self.bluetoothStateHandler.send(data: central.state.name)
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
        getDevice(byId: peripheral.identifier.uuidString)?.setupBLE(client: client)
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
    var name: String {
        switch self {
        case CBManagerState.poweredOn:
            return "poweredOn"
        case CBManagerState.poweredOff:
            return "poweredOff"
        case CBManagerState.resetting:
            return "resetting"
        case CBManagerState.unauthorized:
            return "unauthorized"
        case CBManagerState.unknown:
            return "unknown"
        case CBManagerState.unsupported:
            return "unsupported"
        @unknown default:
            return "other"
        }
    }
}
