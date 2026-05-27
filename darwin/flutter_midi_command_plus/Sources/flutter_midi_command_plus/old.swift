//
//  old.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 26/05/2026.
//

/*

 
 
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
 class ConnectedVirtualOrNativeDevice: ConnectedDevice {
     var client: MIDIClientRef

     init(
         id: String,
         type: String,
         streamHandler: StreamHandler,
         client: MIDIClientRef,
     ) {
         self.client = client
         //self.portEndPoints = [MIDIClientRef](repeating: MIDIClientRef(), count: ports.count)
         deviceInfo = [
             "name": name,
             "id": String(id),
             "type": type,
             "connected": String(true),
         ]

         super.init(id: id, type: type, streamHandler: streamHandler)
     }

     override func send(port: UInt64, bytes: [UInt8], timestamp: UInt64?) {
         print("send \(bytes.count) bytes to \(String(describing: name))")
         let pid = MIDIPortRef(UInt32(port))
         /*
         let outputPort: MIDIPortRef =
         if let ep = ports {
             splitDataIntoMIDIPackets(bytes: bytes, timestamp: timestamp) {
                 packetListPointer in
                 var port = outputPort
                 if let portId = portId {
                     port = MIDIPortRef(UInt32(portId))
                 }
                 MIDISend(port, ep, packetListPointer)
             }
         } else {
             print("No MIDI destination for id \(name!)")
         }
          */
     }

     func splitDataIntoMIDIPackets(
         bytes: [UInt8],
         timestamp: UInt64?,
         packetCallback: (UnsafePointer<MIDIPacketList>) -> Void
     ) {
         let maxPacketSize = 256  // Maximum size for a single packet's data field
         var offset = 0
         let ts = timestamp ?? mach_absolute_time()

         while offset < bytes.count {
             var packetList = MIDIPacketList()

             // Calculate the size of the current chunk
             let chunkSize = min(maxPacketSize, bytes.count - offset)
             let chunk = Array(bytes[offset..<offset + chunkSize])

             // Create the packet
             chunk.withUnsafeBufferPointer { buffer in
                 packetList = buffer.withMemoryRebound(to: UInt8.self) {
                     dataBuffer in
                     var tempPacketList = MIDIPacketList(
                         numPackets: 1,
                         packet: MIDIPacket()
                     )

                     var packet = MIDIPacket()
                     packet.timeStamp = ts
                     packet.length = UInt16(dataBuffer.count)
                     withUnsafeMutablePointer(to: &packet.data) {
                         $0.withMemoryRebound(
                             to: UInt8.self,
                             capacity: dataBuffer.count
                         ) { dataPtr in
                             for i in 0..<dataBuffer.count {
                                 dataPtr[i] = dataBuffer[i]
                             }
                         }
                     }

                     tempPacketList.packet = packet
                     return tempPacketList
                 }
             }

             // Send the packet
             withUnsafePointer(to: &packetList) { packetListPointer in
                 packetCallback(packetListPointer)
             }

             // Move to the next chunk
             offset += chunkSize
         }
     }

     override func close() {
         // We did not create the endpoint so we should not dispose it.
         // if let oEP = outEndpoint {
         //   MIDIEndpointDispose(oEP)
         // }

         /*
         if let iS = inSource {
             MIDIPortDisconnectSource(inputPort, iS)
         }
         MIDIPortDispose(inputPort)
         MIDIPortDispose(outputPort)
          */
     }

     var buffer = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 2)  // Don't know why I need to a capacity of 2 here.

     func handlePacketList(
         _ packetList: UnsafePointer<MIDIPacketList>,
         srcConnRefCon: UnsafeMutableRawPointer?
     ) {
         let packets = packetList.pointee
         let packet: MIDIPacket = packets.packet
         var ap = buffer
         buffer.initialize(to: packet)

         for _ in 0..<packets.numPackets {
             let p = ap.pointee
             var tmp = p.data
             let data = Data(bytes: &tmp, count: Int(p.length))
             let timestamp = p.timeStamp
             parseData(data: data, timestamp: timestamp)
             ap = MIDIPacketNext(ap)
         }
     }

     enum PARSER_STATE {
         case HEADER
         case PARAMS
         case SYSEX
     }

     var parserState = PARSER_STATE.HEADER
     var sysExBuffer: [UInt8] = []
     var midiBuffer: [UInt8] = []
     var midiPacketLength: Int = 0
     var statusByte: UInt8 = 0

     func parseData(data: Data, timestamp: UInt64) {
         if data.count > 0 {
             for i in 0...data.count - 1 {
                 let midiByte: UInt8 = data[i]
                 let midiInt = midiByte & 0xFF

                 //          Log.d("FlutterMIDICommand", "parserState $parserState byte $midiByte")

                 switch parserState {
                 case PARSER_STATE.HEADER:
                     if midiInt == 0xF0 {
                         parserState = PARSER_STATE.SYSEX
                         sysExBuffer.removeAll()
                         sysExBuffer.append(midiByte)
                     } else if midiInt & 0x80 == 0x80 {
                         // some kind of midi msg
                         statusByte = midiByte
                         midiPacketLength = lengthOfMessageType(type: midiInt)
                         midiBuffer.removeAll()
                         midiBuffer.append(midiByte)
                         parserState = PARSER_STATE.PARAMS
                         finalizeMessageIfComplete(timestamp: timestamp)
                     } else {
                         // in header state but no status byte, do running status
                         midiBuffer.removeAll()
                         midiBuffer.append(statusByte)
                         midiBuffer.append(midiByte)
                         parserState = PARSER_STATE.PARAMS
                         finalizeMessageIfComplete(timestamp: timestamp)
                     }
                     break

                 case PARSER_STATE.SYSEX:
                     //                if (midiInt == 0xF0) {
                     //                  // Android can skip SysEx end bytes, when more sysex messages are coming in succession.
                     //                  // in an attempt to save the situation, add an end byte to the current buffer and start a new one.
                     //                  sysExBuffer.append(0xF7)
                     ////                Log.d("FlutterMIDICommand", "sysex force finalized $sysExBuffer")
                     //                    streamHandler.send(data: ["data": sysExBuffer, "timestamp":timestamp, "device":deviceInfo])
                     //                  sysExBuffer.removeAll();
                     //                }
                     sysExBuffer.append(midiByte)
                     if midiInt == 0xF7 {
                         // Sysex complete
                         let sysExBufferCopy: [UInt8] = self.sysExBuffer  // local copy of data to be handled async
                         DispatchQueue.main.async {
                             self.streamHandler.send(
                                 data: [
                                     "data": sysExBufferCopy,
                                     "timestamp": timestamp,
                                     "device": self.deviceInfo,
                                 ] as [String: Any]
                             )
                         }
                         parserState = PARSER_STATE.HEADER
                     }
                     break

                 case PARSER_STATE.PARAMS:
                     midiBuffer.append(midiByte)
                     finalizeMessageIfComplete(timestamp: timestamp)
                     break
                 }
             }
         }
     }

     func finalizeMessageIfComplete(timestamp: UInt64) {
         if midiBuffer.count == midiPacketLength {
             let midiData =
                 [
                     "data": midiBuffer, "timestamp": timestamp,
                     "deviceId": deviceInfo.id,
                 ] as [String: Any]
             DispatchQueue.main.async {
                 self.streamHandler.send(data: midiData)
             }
             parserState = PARSER_STATE.HEADER
         }
     }

     func lengthOfMessageType(type: UInt8) -> Int {
         let midiType: UInt8 = type & 0xF0

         switch type {
         case 0xF6, 0xF8, 0xFA, 0xFB, 0xFC, 0xFF, 0xFE: return 1
         case 0xF1, 0xF3: return 2
         case 0xF2: return 3
         default:
             break
         }

         switch midiType {
         case 0xC0, 0xD0: return 2
         case 0x80, 0x90, 0xA0, 0xB0, 0xE0: return 3
         default: break
         }
         return 0
     }

 }
 ////////////////////////////////////////////////////////////////////////////////////////////
 ////////////////////////////////////////////////////////////////////////////////////////////
class ConnectedNativeDevice: ConnectedVirtualOrNativeDevice {
    var entity: MIDIEntityRef?
    override init(
        id: String,
        type: String,
        streamHandler: StreamHandler,
        client: MIDIClientRef,
    ) {
        super.init(
            id: id,
            type: type,
            streamHandler: streamHandler,
            client: client,
        )

        let idParts = id.split(separator: ":")

        // Store entity and get device/entity name
        if let deviceId = MIDIDeviceRef(idParts[0]) {
            if let entityId = Int(idParts[1]) {
                entity = MIDIDeviceGetEntity(deviceId, entityId)
                if let e = entity {
                    let entityName =
                        FlutterMidiCommandPlusPlugin.getMIDIProperty(
                            kMIDIPropertyName,
                            fromObject: e
                        )

                    var device: MIDIDeviceRef = 0
                    MIDIEntityGetDevice(e, &device)
                    let deviceName =
                        FlutterMidiCommandPlusPlugin.getMIDIProperty(
                            kMIDIPropertyName,
                            fromObject: device
                        )

                    name = "\(deviceName) \(entityName)"
                } else {
                    print("no entity")
                }
            } else {
                print("no entityId")
            }
        } else {
            print("no deviceId")
        }

        deviceInfo = [
            "name": name,
            "id": String(id),
            "type": "native",
        ]

        /*
        // MIDI Input with handler
        MIDIInputPortCreateWithBlock(
            client,
            "FlutterMidiCommand_InPort" as CFString,
            &inputPort
        ) { (packetList, srcConnRefCon) in
            self.handlePacketList(packetList, srcConnRefCon: srcConnRefCon)
        }
        
        // MIDI output
        MIDIOutputPortCreate(
            client,
            "FlutterMidiCommand_OutPort" as CFString,
            &outputPort
        )
        */
        openPorts()
    }
    /*
        override func openPorts() {
            print("open native ports")
    
            if let e = entity {
    
                let ref = Unmanaged.passUnretained(self).toOpaque()
    
                if let ps = ports {
                    for port in ps {
                        inSource = MIDIEntityGetSource(e, port.id)
    
                        switch port.type {
                        case "MidiPortType.IN":
                            let status = MIDIPortConnectSource(
                                inputPort,
                                inSource!,
                                ref
                            )
                            print("port open status \(status)")
                        case "MidiPortType.OUT":
                            outEndpoint = MIDIEntityGetDestination(e, port.id)
                            //                    print("port endpoint \(endpoint)")
                            break
                        default:
                            print("unknown port type \(port.type)")
                        }
                    }
                }
            }
        }
    */
    override func close() {
        /*
         if let oEP = outEndpoint {
         MIDIEndpointDispose(oEP)
         }
         */
        /*
        if let iS = inSource {
            MIDIPortDisconnectSource(inputPort, iS)
        }
        
        MIDIPortDispose(inputPort)
        MIDIPortDispose(outputPort)
         */
    }

    override func handlePacketList(
        _ packetList: UnsafePointer<MIDIPacketList>,
        srcConnRefCon: UnsafeMutableRawPointer?
    ) {
        //        let deviceInfo = ["name" : name,
        //                          "id": String(id),
        //                          "type":"native"]

        var timestampFactor: Double = 1.0
        var tb = mach_timebase_info_data_t()
        let kError = mach_timebase_info(&tb)
        if kError == 0 {
            timestampFactor = Double(tb.numer) / Double(tb.denom)
        }

            let packetListSize = MIDIPacketList.sizeInBytes(pktList: packetList)

            // Copy raw data from packetList
            let packetListAsRawData = Data(
                bytes: packetList,
                count: packetListSize
            )
            var packetNumber = 0

            for packet in packetList.unsafeSequence() {
                let offsetStart = getOffsetForPackageData(
                    packetList: packetList,
                    packageNumber: (Int)(packetNumber)
                )
                let offsetEnd = (offsetStart + (Int)(packet.pointee.length) - 1)
                let packetData = packetListAsRawData.subdata(
                    in: Range(offsetStart...offsetEnd)
                )

                let timestamp = UInt64(
                    round(Double(packet.pointee.timeStamp) * timestampFactor)
                )

                parseData(data: packetData, timestamp: timestamp)

                packetNumber += 1
            }
    }

    func getOffsetForPackageData(
        packetList: UnsafePointer<MIDIPacketList>,
        packageNumber: Int
    ) -> Int {
        if #available(macOS 10.15, iOS 13.0, *) {
            var packageCount = 0
            for packet in packetList.unsafeSequence() {
                if packageCount == packageNumber {
                    return (Int)(
                        UInt(bitPattern: Int(Int(bitPattern: packet)))
                            - UInt(bitPattern: Int(Int(bitPattern: packetList)))
                    ) + MemoryLayout.offset(of: \MIDIPacket.data)!
                }

                packageCount += 1
            }
        }
        return -1
    }
}
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
class ConnectedVirtualDevice: ConnectedVirtualOrNativeDevice {

    override init(
        id: String,
        type: String,
        streamHandler: StreamHandler,
        client: MIDIClientRef,
    ) {

        super.init(
            id: id,
            type: type,
            streamHandler: streamHandler,
            client: client,
        )

        let idParts = id.split(separator: ":")
        assert(idParts.count > 0)
        /*
        outEndpoint =
            idParts.count > 0 && idParts[0].count > 0
            ? MIDIEndpointRef(idParts[0]) : nil
        inSource =
            idParts.count > 1 && idParts[1].count > 0
            ? MIDIEndpointRef(idParts[1]) : nil
        
        name = displayName(endpoint: outEndpoint ?? inSource ?? 0)
        
        // MIDI Input with handler
        MIDIInputPortCreateWithBlock(
            client,
            "FlutterMidiCommand_InPort" as CFString,
            &inputPort
        ) { (packetList, srcConnRefCon) in
            self.handlePacketList(packetList, srcConnRefCon: srcConnRefCon)
        }
        
        // MIDI output
        MIDIOutputPortCreate(
            client,
            "FlutterMidiCommand_OutPort" as CFString,
            &outputPort
        )
        */
        openPorts()
    }

    /*
    override func openPorts() {
    
        if inSource != nil {
            let ref = Unmanaged.passUnretained(self).toOpaque()
            MIDIPortConnectSource(inputPort, inSource!, ref)
        }
    }
     */
}
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
class ConnectedOwnVirtualDevice: ConnectedVirtualOrNativeDevice {
    init(name: String, streamHandler: StreamHandler, client: MIDIClientRef) {
        self.deviceName = name
        self.midiClient = client
        super.init(
            id: String(stringToId(str: name)),
            type: "own-virtual",
            streamHandler: streamHandler,
            client: client,
        )
        initVirtualSource()
        initVirtualDestination()
        self.name = name
    }

    override func openPorts() {}

    var virtualSourceEndpoint: MIDIClientRef = 0
    var virtualDestinationEndpoint: MIDIClientRef = 0
    let midiClient: MIDIClientRef
    let deviceName: String
    var isConnected = false
    var errors: [String] = []

    override func send(port: UInt64, bytes: [UInt8], timestamp: UInt64?) {

        if !isConnected {
            return
        }

        splitDataIntoMIDIPackets(bytes: bytes, timestamp: timestamp) {
            packetListPointer in
            let status = MIDIReceived(virtualSourceEndpoint, packetListPointer)
            if status != noErr {
                let error =
                    "Error \(status) while publishing MIDI on own virtual source endpoint."
                errors.append(error)
                print(error)
            }
        }
    }

    override func close() {
        closeVirtualSource()
        closeVirtualDestination()
    }

    func initVirtualSource() {
        let s = MIDISourceCreate(
            midiClient,
            deviceName as CFString,
            &virtualSourceEndpoint
        )
        if s != noErr {
            let error = "Error \(s) while create MIDI virtual source"
            errors.append(error)
            print(error)
            return
        }

        // Attempt to use saved unique ID
        let defaults = UserDefaults.standard
        var uniqueID = Int32(
            defaults.integer(
                forKey:
                    "FlutterMIDICommand Saved Virtual Source ID \(deviceName)"
            )
        )

        //Set unique ID if available
        if uniqueID != 0 {
            let s = MIDIObjectSetIntegerProperty(
                virtualSourceEndpoint,
                kMIDIPropertyUniqueID,
                uniqueID
            )

            if s == kMIDIIDNotUnique {
                uniqueID = 0
            }
        }

        // Create and save a new unique id
        if uniqueID == 0 {
            let s = MIDIObjectGetIntegerProperty(
                virtualSourceEndpoint,
                kMIDIPropertyUniqueID,
                &uniqueID
            )
            if s != noErr {
                let error = "Error \(s) while getting MIDI virtual source ID"
                errors.append(error)
                print(error)
            }

            if s == noErr {
                defaults.set(
                    uniqueID,
                    forKey:
                        "FlutterMIDICommand Saved Virtual Source ID \(deviceName)"
                )
            }
        }
    }

    func closeVirtualSource() {
        let s = MIDIEndpointDispose(virtualSourceEndpoint)
        if s != noErr {
            let error = "Error \(s) while disposing MIDI virtual source."
            errors.append(error)
            print(error)
        }
    }

    func initVirtualDestination() {

        let s = MIDIDestinationCreateWithBlock(
            midiClient,
            deviceName as CFString,
            &virtualDestinationEndpoint
        ) { (packetList, srcConnRefCon) in
            if self.isConnected {
                self.handlePacketList(packetList, srcConnRefCon: srcConnRefCon)
            }
        }

        if s != noErr {
            if s == -10844 {
                let error =
                    "Error while creating virtual MIDI destination. You need to add the key 'UIBackgroundModes' with value 'audio' to your Info.plist file"
                errors.append(error)
                print(error)
            }
            return
        }

        // Attempt to use saved unique ID
        let defaults = UserDefaults.standard
        var uniqueID = Int32(
            defaults.integer(
                forKey:
                    "FlutterMIDICommand Saved Virtual Destination ID  \(deviceName)"
            )
        )

        if uniqueID != 0 {
            let s = MIDIObjectSetIntegerProperty(
                virtualDestinationEndpoint,
                kMIDIPropertyUniqueID,
                uniqueID
            )
            if s == kMIDIIDNotUnique {
                uniqueID = 0
            }
        }
        // Save the ID
        if uniqueID == 0 {
            let s = MIDIObjectGetIntegerProperty(
                virtualDestinationEndpoint,
                kMIDIPropertyUniqueID,
                &uniqueID
            )

            if s == noErr {
                defaults.set(
                    uniqueID,
                    forKey:
                        "FlutterMIDICommand Saved Virtual Destination ID \(deviceName)"
                )
            } else {
                let error =
                    "Error: \(s) while setting unique ID for virtuel endpoint"
                errors.append(error)
                print(error)
            }
        }
    }

    func closeVirtualDestination() {
        let s = MIDIEndpointDispose(virtualDestinationEndpoint)
        if s != 0 {
            let error = "Error: \(s) while disposing MIDI endpoint"
            errors.append(error)
            print(error)
        }
    }
}
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
class ConnectedBLEDevice: ConnectedDevice, CBPeripheralDelegate {
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

    var setupStream: StreamHandler?
    var connectResult: FlutterResult?

    init(
        id: String,
        type: String,
        streamHandler: StreamHandler,
        result: FlutterResult?,
        peripheral: CBPeripheral,
    ) {
        self.peripheral = peripheral
        self.connectResult = result
        super.init(id: id, type: type, streamHandler: streamHandler)
    }

    func setupBLE(stream: StreamHandler) {
        setupStream = stream
        peripheral.delegate = self
        peripheral.discoverServices([
            CBUUID(string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700")
        ])
    }

    override func close() {
        CBCentralManager().cancelPeripheralConnection(peripheral)
        characteristic = nil
    }

    override func send(port: UInt64, bytes: [UInt8], timestamp: UInt64?) {
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
                let isCompleteCommand =
                    endReached || (dataBytes[i + 1] & 0x80) != 0

                if isCompleteCommand {
                    enqueueMidiData(bytes: currentBuffer)
                    currentBuffer = Data()
                }
            }
        } else {
            print("No peripheral/characteristic in device")
        }
    }

    let writeType = CBCharacteristicWriteType.withoutResponse
    var outboundMessageQueue = [Data]()

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
        peripheral.writeValue(
            messageBytes,
            for: characteristic!,
            type: writeType
        )
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        dequeueMidiBytes()
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let err = error {
            print(
                "error writing to characteristic \(String(describing: characteristic.properties)): \(err.localizedDescription)"
            )
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        print(
            "perif didDiscoverServices  \(String(describing: peripheral.services))"
        )
        for service: CBService in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        print(
            "perif didDiscoverCharacteristicsFor  \(String(describing: service.characteristics))"
        )
        for characteristic: CBCharacteristic in service.characteristics! {
            if characteristic.uuid.uuidString
                == "7772E5DB-3868-4112-A1A9-F2669D106BF3"
            {
                self.characteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("set up characteristic for device")
                DispatchQueue.main.async {
                    self.setupStream?.send(data: "deviceConnected")
                }

                if let res = connectResult {
                    print("callback result")
                    res(nil)
                } else {
                    print("NO callback result")
                }
                return
            }
        }

        if let res = connectResult {
            res(
                FlutterError.init(
                    code: "BLEERROR",
                    message: "Did not discover MIDI characteristics",
                    details: id
                )
            )
        }
    }

    func createMessageEvent(
        _ bytes: [UInt8],
        timestamp: UInt64,
        peripheral: CBPeripheral
    ) {
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
                ] as [String: Any]
            )
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
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

                if (((midiByte & 0x80) == 0x80)
                    && (bleHandlerState != BLE_HANDLER_STATE.TIMESTAMP))
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
                            bleMidiBuffer,
                            timestamp: timestamp,
                            peripheral: peripheral
                        )  // TODO Add timestamp
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
                            bleMidiBuffer,
                            timestamp: timestamp,
                            peripheral: peripheral
                        )
                    }
                    break

                case BLE_HANDLER_STATE.PARAMS:
                    //                print ("add param \(midiByte)")
                    bleMidiBuffer.append(midiByte)

                    if bleMidiPacketLength == bleMidiBuffer.count {
                        createMessageEvent(
                            bleMidiBuffer,
                            timestamp: timestamp,
                            peripheral: peripheral
                        )
                        bleMidiBuffer.removeLast(Int(bleMidiPacketLength) - 1)  // Remove all but status, which might be used for running msgs
                    }
                    break

                case BLE_HANDLER_STATE.SYSTEM_RT:
                    //                print("handle RT")
                    createMessageEvent(
                        [midiByte],
                        timestamp: timestamp,
                        peripheral: peripheral
                    )
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
                    createMessageEvent(
                        sysExBuffer,
                        timestamp: 0,
                        peripheral: peripheral
                    )
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
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
*/
