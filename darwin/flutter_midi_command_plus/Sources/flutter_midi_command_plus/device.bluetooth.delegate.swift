//
//  device.bluetooth.delgate.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 27/05/2026.
//

import CoreBluetooth
import Foundation

#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif


class BluetoothDeviceDelegate : NSObject, CBPeripheralDelegate {
    var client:Client?
    var device: BluetoothDevice
    var peripheral: CBPeripheral
    var characteristic: CBCharacteristic?

    // BLE MIDI parsing
    enum BLE_HANDLER_STATE {
        case HEADER
        case TIMESTAMP
        case STATUS
        case STATUS_RUNNING
        case PARAMS
        case SYSTEM_RT
        case SYSEX
        case SYSEX_END
        case SYSEX_INT
    }

    var bleHandlerState = BLE_HANDLER_STATE.HEADER

    var sysExBuffer: [UInt8] = []
    var timestamp: UInt64 = 0
    var bleMidiBuffer: [UInt8] = []
    var bleMidiPacketLength: UInt8 = 0
    var bleSysExHasFinished = true
    var isBusy = false

    let writeType = CBCharacteristicWriteType.withoutResponse
    var outboundMessageQueue = [Data]()

    init(device: BluetoothDevice, peripheral: CBPeripheral) {
        self.device = device
        self.peripheral = peripheral
        super.init()
    }

    deinit {
        CBCentralManager().cancelPeripheralConnection(peripheral)
    }
    
    func setupBLE(client:Client) {
        self.client = client
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700")])
    }

    
    func send(bytes: [UInt8], timestamp: UInt64?) {
        //        print("ble send \(id) \(bytes)")
        if characteristic != nil {

            let packetSize = peripheral.maximumWriteValueLength(for: writeType)
            //             print("packetSize = \(packetSize)")

            var dataBytes = Data(bytes)

            if bytes.first == 0xF0 && bytes.last == 0xF7 {  //  this is a sysex message, handle carefully
                if bytes.count > packetSize - 3 {  // Split into multiple messages of 20 bytes total

                    // First packet
                    var packet = dataBytes.subdata(in: 0..<packetSize - 2)

                    //                    print("count \(dataBytes.count)")

                    // Insert header(and empty timstamp high) and timestamp low in front Sysex Start
                    packet.insert(0x80, at: 0)
                    packet.insert(0x80, at: 0)

                    //                        print("packet \(packet)")
                    //                        print("packet \(hexEncodedString(packet))")

                    enqueueMidiData(bytes: packet)

                    dataBytes = dataBytes.advanced(by: packetSize - 2)

                    // More packets
                    while dataBytes.count > 0 {

                        print("count \(dataBytes.count)")

                        let pickCount = min(dataBytes.count, packetSize - 1)
                        //                            print("pickCount \(pickCount)")
                        packet = dataBytes.subdata(in: 0..<pickCount)  // Pick bytes for packet

                        // Insert header
                        packet.insert(0x80, at: 0)

                        if packet.count < packetSize {  // Last packet
                            // Timestamp before Sysex End byte
                            print("insert end")
                            packet.insert(0x80, at: packet.count - 1)
                        }

                        //                            print("packet \(hexEncodedString(packet))")

                        // Wait for buffer to clear
                        enqueueMidiData(bytes: packet)

                        if dataBytes.count > packetSize - 2 {
                            dataBytes = dataBytes.advanced(by: pickCount)  // Advance buffer
                        } else {
                            print("done")
                            return
                        }
                    }
                } else {
                    // Insert timestamp low in front of Sysex End-byte
                    dataBytes.insert(0x80, at: bytes.count - 1)

                    // Insert header(and empty timstamp high) and timestamp low in front of BLE Midi message
                    dataBytes.insert(0x80, at: 0)
                    dataBytes.insert(0x80, at: 0)

                    enqueueMidiData(bytes: dataBytes)
                }
                return
            }

            // In bluetooth MIDI we need to send each midi command separately
            var currentBuffer = Data()
            for i in 0..<dataBytes.count {
                let byte = dataBytes[i]

                // Insert header(and empty timstamp high) and timestamp
                // low in front of BLE Midi message
                if (byte & 0x80) != 0 {
                    currentBuffer.insert(0x80, at: 0)
                    currentBuffer.insert(0x80, at: 0)
                }
                currentBuffer.append(byte)

                // Send each MIDI command separately
                let endReached = i == (dataBytes.count - 1)
                let isCompleteCommand = endReached || (dataBytes[i + 1] & 0x80) != 0

                if isCompleteCommand {
                    enqueueMidiData(bytes: currentBuffer)
                    currentBuffer = Data()
                }
            }
        } else {
            print("No peripheral/characteristic in device")
        }
    }


    func enqueueMidiData(bytes: Data) {
        outboundMessageQueue.append(bytes)

        if peripheral.canSendWriteWithoutResponse && !isBusy {
            dequeueMidiBytes()
        }
    }

    func dequeueMidiBytes() {
        if outboundMessageQueue.isEmpty {
            print("Can't dequeue empty queue - return")
            isBusy = false
            return
        }
        isBusy = true
        let messageBytes = outboundMessageQueue.removeFirst()
        peripheral.writeValue(messageBytes, for: characteristic!, type: writeType)
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        dequeueMidiBytes()
    }

    func createMessageEvent(_ bytes: [UInt8], timestamp: UInt64, peripheral: CBPeripheral) {
        //        print("send rx event \(bytes)")
        let data = Data(bytes: bytes, count: Int(bytes.count))
        DispatchQueue.main.async {
            self.streamHandler.send(
                data: [
                    "data": data, "timestamp": timestamp,
                    "device": [
                        "name": peripheral.name ?? "-",
                        "id": peripheral.identifier.uuidString,
                        "type": "BLE",
                    ],
                ] as [String: Any])
        }
    }


    public func peripheral(
        _ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?
    ) {
        if let err = error {
            print(
                "error writing to characteristic \(String(describing: characteristic.properties)): \(err.localizedDescription)"
            )
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("perif didDiscoverServices  \(String(describing: peripheral.services))")
        for service: CBService in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
    ) {
        print("perif didDiscoverCharacteristicsFor  \(String(describing: service.characteristics))")
        for characteristic: CBCharacteristic in service.characteristics! {
            if characteristic.uuid.uuidString == "7772E5DB-3868-4112-A1A9-F2669D106BF3" {
                self.characteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("set up characteristic for device")
                self.client?.sendState("deviceConnected")
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        // print("perif didUpdateValueFor  \(String(describing: characteristic))")
        if let value = characteristic.value {
            parseBLEPacket(value, peripheral: peripheral)
        }
    }

    func parseBLEPacket(_ packet: Data, peripheral: CBPeripheral) {
        //        print("parse \(packet.map { String(format: "%02hhx ", $0) }.joined())")

        if packet.count > 1 {
            // parse BLE message
            bleHandlerState = BLE_HANDLER_STATE.HEADER

            let header = packet[0]
            var statusByte: UInt8 = 0

            for i in 1...packet.count - 1 {
                let midiByte: UInt8 = packet[i]
                //              print ("from bleHandlerState \(bleHandlerState) byte \(midiByte)")

                if (((midiByte & 0x80) == 0x80) && (bleHandlerState != BLE_HANDLER_STATE.TIMESTAMP))
                    && (bleHandlerState != BLE_HANDLER_STATE.SYSEX_INT)
                {
                    if !bleSysExHasFinished {
                        //                      print("Set to SYSEX_INT")
                        bleHandlerState = BLE_HANDLER_STATE.SYSEX_INT
                    } else {
                        bleHandlerState = BLE_HANDLER_STATE.TIMESTAMP
                    }
                } else {

                    // State handling
                    switch bleHandlerState
                    {
                    case BLE_HANDLER_STATE.HEADER:
                        if !bleSysExHasFinished {
                            if (midiByte & 0x80) == 0x80 {  // System messages can interrupt ongoing sysex
                                bleHandlerState = BLE_HANDLER_STATE.SYSEX_INT
                            } else {
                                // Sysex continue
                                //print("sysex continue")
                                bleHandlerState = BLE_HANDLER_STATE.SYSEX
                            }
                        }
                        break

                    case BLE_HANDLER_STATE.TIMESTAMP:
                        if (midiByte & 0xFF) == 0xF0 {  // Sysex start
                            bleSysExHasFinished = false
                            sysExBuffer.removeAll()
                            bleHandlerState = BLE_HANDLER_STATE.SYSEX
                        } else if (midiByte & 0x80) == 0x80 {  // Status/System start
                            bleHandlerState = BLE_HANDLER_STATE.STATUS
                        } else {
                            bleHandlerState = BLE_HANDLER_STATE.STATUS_RUNNING
                        }
                        break

                    case BLE_HANDLER_STATE.STATUS:
                        bleHandlerState = BLE_HANDLER_STATE.PARAMS
                        break

                    case BLE_HANDLER_STATE.STATUS_RUNNING:
                        bleHandlerState = BLE_HANDLER_STATE.PARAMS
                        break

                    case BLE_HANDLER_STATE.PARAMS:  // After params can come TSlow or more params
                        break

                    case BLE_HANDLER_STATE.SYSEX:
                        break

                    case BLE_HANDLER_STATE.SYSEX_INT:
                        if (midiByte & 0xFF) == 0xF7 {  // Sysex end
                            //                        print("sysex end")
                            bleSysExHasFinished = true
                            bleHandlerState = BLE_HANDLER_STATE.SYSEX_END
                        } else {
                            bleHandlerState = BLE_HANDLER_STATE.SYSTEM_RT
                        }
                        break

                    case BLE_HANDLER_STATE.SYSTEM_RT:
                        if !bleSysExHasFinished {  // Continue incomplete Sysex
                            bleHandlerState = BLE_HANDLER_STATE.SYSEX
                        }
                        break

                    default:
                        print("Unhandled state \(bleHandlerState)")
                        break
                    }
                }

                //                print ("handle \(bleHandlerState) - \(midiByte) [\(String(format:"%02X", midiByte))]")

                // Data handling
                switch bleHandlerState
                {
                case BLE_HANDLER_STATE.TIMESTAMP:
                    //                print ("set timestamp")
                    let tsHigh = header & 0x3f
                    let tsLow = midiByte & 0x7f
                    timestamp = UInt64(tsHigh) << 7 | UInt64(tsLow)
                    //                print ("timestamp is \(timestamp)")
                    break

                case BLE_HANDLER_STATE.STATUS:

                    bleMidiPacketLength = lengthOfMessageType(midiByte)
                    //                print("message length \(bleMidiPacketLength)")
                    bleMidiBuffer.removeAll()
                    bleMidiBuffer.append(midiByte)

                    if bleMidiPacketLength == 1 {
                        createMessageEvent(
                            bleMidiBuffer, timestamp: timestamp, peripheral: peripheral)  // TODO Add timestamp
                    } else {
                        //                    print ("set status")
                        statusByte = midiByte
                    }
                    break

                case BLE_HANDLER_STATE.STATUS_RUNNING:
                    //                print("set running status")
                    bleMidiPacketLength = lengthOfMessageType(statusByte)
                    bleMidiBuffer.removeAll()
                    bleMidiBuffer.append(statusByte)
                    bleMidiBuffer.append(midiByte)

                    if bleMidiPacketLength == 2 {
                        createMessageEvent(
                            bleMidiBuffer, timestamp: timestamp, peripheral: peripheral)
                    }
                    break

                case BLE_HANDLER_STATE.PARAMS:
                    //                print ("add param \(midiByte)")
                    bleMidiBuffer.append(midiByte)

                    if bleMidiPacketLength == bleMidiBuffer.count {
                        createMessageEvent(
                            bleMidiBuffer, timestamp: timestamp, peripheral: peripheral)
                        bleMidiBuffer.removeLast(Int(bleMidiPacketLength) - 1)  // Remove all but status, which might be used for running msgs
                    }
                    break

                case BLE_HANDLER_STATE.SYSTEM_RT:
                    //                print("handle RT")
                    createMessageEvent([midiByte], timestamp: timestamp, peripheral: peripheral)
                    break

                case BLE_HANDLER_STATE.SYSEX:
                    //                print("add sysex")
                    sysExBuffer.append(midiByte)
                    break

                case BLE_HANDLER_STATE.SYSEX_INT:
                    //                print("sysex int")
                    break

                case BLE_HANDLER_STATE.SYSEX_END:
                    //                print("finalize sysex")
                    sysExBuffer.append(midiByte)
                    createMessageEvent(sysExBuffer, timestamp: 0, peripheral: peripheral)
                    break

                default:
                    print("Unhandled state (data) \(bleHandlerState)")
                    break
                }
            }
        }
    }

    func lengthOfMessageType(_ type: UInt8) -> UInt8 {
        let midiType: UInt8 = type & 0xF0

        switch type {
        case 0xF6, 0xF8, 0xFA, 0xFB, 0xFC, 0xFF, 0xFE:
            return 1
        case 0xF1, 0xF3:
            return 2
        case 0xF2:
            return 3
        default:
            break
        }

        switch midiType {
        case 0xC0, 0xD0:
            return 2
        case 0x80, 0x90, 0xA0, 0xB0, 0xE0:
            return 3
        default:
            break
        }
        return 0
    }


}
