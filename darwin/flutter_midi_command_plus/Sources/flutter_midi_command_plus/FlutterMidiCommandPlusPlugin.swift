// Import the correct Flutter module and UI framework for each platform
#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import Cocoa
#endif

public class FlutterMidiCommandPlusPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // The registrar's `messenger` is a method on iOS and a property on macOS.
    // Use a compile-time condition to handle this difference.
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(name: "flutter_midi_command_plus", binaryMessenger: messenger)
    let instance = FlutterMidiCommandPlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      // Use compile-time conditions to return the correct OS version string.
      #if os(iOS)
        result("iOS " + UIDevice.current.systemVersion)
      #elseif os(macOS)
        result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
      #else
        // A fallback for any other Apple platform that might be supported in the future.
        result(FlutterMethodNotImplemented)
      #endif
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
