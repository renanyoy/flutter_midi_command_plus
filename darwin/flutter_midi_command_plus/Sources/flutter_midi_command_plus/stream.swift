//
//  stream.swift
//  flutter_midi_command_plus
//
//  Created by renan jegouzo on 26/05/2026.
//

import Foundation

#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif

////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
class StreamHandler: NSObject, FlutterStreamHandler {
    var sink: FlutterEventSink?
    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        sink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
    func send(data: Any) {
        if let sink = sink {
            sink(data)
        }
    }
}
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
