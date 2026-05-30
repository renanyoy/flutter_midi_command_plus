import CoreBluetooth
import CoreMIDI
import CoreVideo
import Foundation

// Import the correct Flutter module and UI framework for each platform
#if os(iOS)
    import Flutter
    import UIKit
#elseif os(macOS)
    import FlutterMacOS
    import Cocoa
#endif

///
/// Credit to
/// http://mattg411.com/coremidi-swift-programming/
/// https://github.com/genedelisa/Swift3MIDI
/// http://www.gneuron.com/?p=96
/// https://learn.sparkfun.com/tutorials/midi-ble-tutorial/all
/// https://github.com/InvisibleWrench/FlutterMidiCommand
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
func appName() -> String {
    return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as! String
}

func stringToId(str: String) -> UInt32 {
    return UInt32(str.hash & 0xFFFF)
}
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
public class FlutterMidiCommandPlusPlugin: NSObject, FlutterPlugin {
    let client = Client()

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(macOS)
            var messenger = registrar.messenger
        #else
            var messenger = registrar.messenger()
        #endif
        let channel = FlutterMethodChannel(
            name: "plugins.aestesis.org/flutter_midi_command",
            binaryMessenger: messenger
        )
        let instance = FlutterMidiCommandPlusPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.client.setup(registrar: registrar)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func extractName(arguments: Any?) -> String? {
        var name: String? = nil
        if let packet = arguments as? [String: Any] {
            name = packet["name"] as? String
        }
        return name
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        //        print("call method \(call.method)")
        switch call.method {
        case "startBluetoothCentral":
            result(client.bluetooth.state)
            break
        case "bluetoothState":
            result(client.bluetooth.state)
            break
        case "scanForDevices":
            if client.bluetooth.startScan() {
                result(nil)
            } else {
                print("BT not ready")
                result(
                    FlutterError(
                        code: "MESSAGEERROR",
                        message: "bluetoothNotAvailable",
                        details: call.arguments
                    )
                )
            }
            break
        case "stopScanForDevices":
            client.bluetooth.stopScan()
            break
        case "getDevices":
            let devices = client.devices.map { $0.toDictionary() }
            for d in devices {
                print("\(d)")
            }
            result(devices)
            break
        case "deviceConnected":
            var connected: Bool? = nil
            if let args = call.arguments as? [String: Any] {
                if let id = args["deviceId"] as? String {
                    connected = client.isConnected(deviceId: id)
                    result(connected!)
                }
            }
            if connected == nil {
                result(
                    FlutterError.init(
                        code: "MESSAGEERROR",
                        message: "Could not parse args",
                        details: call.arguments
                    )
                )
            }
            break

        case "connectToDevice":
            if let args = call.arguments as? [String: Any] {
                if let id = args["deviceId"] as? String {
                    if client.connectDevice(deviceId: id) {
                        result(nil)
                    } else {
                        result(
                            FlutterError.init(
                                code: "MESSAGEERROR",
                                message: "unknown device id: \(id)",
                                details: call.arguments
                            )
                        )
                    }
                } else {
                    result(
                        FlutterError.init(
                            code: "MESSAGEERROR",
                            message: "missing deviceId field ina args",
                            details: call.arguments
                        )
                    )
                }
            } else {
                result(
                    FlutterError.init(
                        code: "MESSAGEERROR",
                        message: "Could not parse args",
                        details: call.arguments
                    )
                )
            }
            break
        case "disconnectDevice":
            if let deviceInfo = call.arguments as? [String: Any] {
                if let deviceId = deviceInfo["id"] as? String {
                    client.disconnectDevice(deviceId: deviceId)
                } else {
                    result(
                        FlutterError.init(
                            code: "MESSAGEERROR",
                            message: "No device Id",
                            details: call.arguments
                        )
                    )
                }
                result(nil)
            } else {
                result(
                    FlutterError.init(
                        code: "MESSAGEERROR",
                        message: "Could not parse device id",
                        details: call.arguments
                    )
                )
            }
            result(nil)
            break

        case "sendData":
            if let packet = call.arguments as? [String: Any],
                let deviceId = packet["deviceId"] as? String, let port = packet["port"] as? Int, let data = packet["data"] as? FlutterStandardTypedData
            {
                let words:[UInt32] = data.data.toArray(type: UInt32.self)
                client.transmitMidi(
                    deviceId: deviceId,
                    port: port,
                    data: words,
                    timestamp: packet["timestamp"] as? UInt64 ?? UInt64(0)
                )
                result(nil)
            } else {
                result(
                    FlutterError.init(
                        code: "MESSAGEERROR",
                        message: "Could not form midi packet",
                        details: call.arguments
                    )
                )
            }
            break
        case "teardown":
            // TODO: disconnect all
            break

        case "addVirtualDevice":
            var name: String = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as! String
            if let args = call.arguments as? [String: Any], let n = args["name"] as? String {
                name = n
            }
            let device = client.addVirtualDevice(name: name)
            result(device.toDictionary())
            break

        case "removeVirtualDevice":
            if let args = call.arguments as? [String: Any], let id = args["deviceId"] as? String {
                client.removeVirtualDevice(deviceId: id)
            }
            result(nil)
            break

        case "enableNetworkSession":
            if let enabled = call.arguments as? Bool {
                session?.isEnabled = enabled
            }
        case "isNetworkSessionEnabled":
            result(session?.isEnabled ?? false)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }

}
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
