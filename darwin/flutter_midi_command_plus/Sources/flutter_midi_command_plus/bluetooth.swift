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
    var discoveredDevices: Set<CBPeripheral> = []
    var ongoingConnections = [String: FlutterResult]()
    
    var state : String {
        return central.state.name;
    }
    
    init(client:Client) {
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
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.insert(peripheral)
            client.sendState("deviceAppeared")
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        /*
        print("central did connect \(peripheral)")
        (connectedDevices[peripheral.identifier.uuidString]
            as! ConnectedBLEDevice).setupBLE(stream: setupStreamHandler)
         */
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
        connectedDevices.removeValue(forKey: peripheral.identifier.uuidString)
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
