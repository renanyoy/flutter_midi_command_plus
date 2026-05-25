import 'dart:async';
import 'package:flutter/services.dart';
import 'flutter_midi_command_platform_interface.dart';
import 'midi_device.dart';
import 'midi_packet.dart';
import 'midi_port.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
const MethodChannel _methodChannel = MethodChannel(
  'plugins.invisiblewrench.com/flutter_midi_command',
);
//////////////////////////////////////////////////////////////////////////////////////////////////////////
const EventChannel _rxChannel = EventChannel(
  'plugins.invisiblewrench.com/flutter_midi_command/rx_channel',
);
//////////////////////////////////////////////////////////////////////////////////////////////////////////
const EventChannel _setupChannel = EventChannel(
  'plugins.invisiblewrench.com/flutter_midi_command/setup_channel',
);
//////////////////////////////////////////////////////////////////////////////////////////////////////////
const EventChannel _bluetoothStateChannel = EventChannel(
  'plugins.invisiblewrench.com/flutter_midi_command/bluetooth_central_state',
);

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/// An implementation of [MidiCommandPlatform] that uses method channels.
class MethodChannelMidiCommand extends MidiCommandPlatform {
  Stream<MidiPacket>? _rxStream;
  Stream<String>? _setupStream;
  Stream<String>? _bluetoothStateStream;
  @override
  Future<List<MidiDevice>?> get devices async {
    var devs = await _methodChannel.invokeMethod('getDevices');
    return devs.map<MidiDevice>((m) {
      var map = m.cast<String, Object>();
      var dev = MidiDevice(
        map["id"].toString(),
        map["name"] ?? "-",
        map["type"],
        map["connected"] == "true",
      );
      dev.inputPorts = _portsFromDevice(dev, map["inputs"], .input);
      dev.outputPorts = _portsFromDevice(dev, map["outputs"], .output);
      return dev;
    }).toList();
  }

  List<MidiPort> _portsFromDevice(
    MidiDevice device,
    List<dynamic>? portList,
    MidiPortType type,
  ) {
    if (portList == null) return [];
    var ports = portList.map<MidiPort>((e) {
      var portMap = (e as Map).cast<String, Object>();
      return MidiPort(device.id, portMap["id"] as int, type);
    });
    return ports.toList(growable: false);
  }

  @override
  Future<void> startBluetoothCentral() async {
    try {
      await _methodChannel.invokeMethod('startBluetoothCentral');
    } on PlatformException catch (e) {
      throw e.message!;
    }
  }

  @override
  Stream<String>? get onBluetoothStateChanged {
    _bluetoothStateStream ??= _bluetoothStateChannel
        .receiveBroadcastStream()
        .cast<String>();
    return _bluetoothStateStream;
  }

  @override
  Future<String> bluetoothState() async {
    try {
      return await _methodChannel.invokeMethod('bluetoothState');
    } on PlatformException catch (e) {
      throw e.message!;
    }
  }

  @override
  Future<void> startScanningForBluetoothDevices() async {
    try {
      await _methodChannel.invokeMethod('scanForDevices');
    } on PlatformException catch (e) {
      throw e.message!;
    }
  }

  @override
  void stopScanningForBluetoothDevices() {
    _methodChannel.invokeMethod('stopScanForDevices');
  }

  @override
  Future<void> connectToDevice(MidiDevice device, {List<MidiPort>? ports}) {
    return _methodChannel.invokeMethod('connectToDevice', {
      "device": device.toDictionary,
      "ports": ports,
    });
  }

  @override
  void disconnectDevice(MidiDevice device) {
    _methodChannel.invokeMethod('disconnectDevice', device.toDictionary);
  }

  @override
  void teardown() {
    _methodChannel.invokeMethod('teardown');
  }

  @override
  void sendData(
    Uint8List data, {
    int? timestamp,
    String? deviceId,
    int? portId,
  }) {
    _methodChannel.invokeMethod('sendData', {
      "data": data,
      "timestamp": timestamp,
      "deviceId": deviceId,
      "portId": portId,
    });
  }

  @override
  Stream<MidiPacket>? get onMidiDataReceived {
    // print("get on midi data");
    _rxStream ??= _rxChannel.receiveBroadcastStream().map<MidiPacket>((d) {
      var port = MidiPort(d['deviceId'], d["portId"], .input);
      return MidiPacket(
        Uint8List.fromList(List<int>.from(d["data"])),
        d["timestamp"] as int,
        port,
      );
    });
    return _rxStream;
  }

  @override
  Stream<String>? get onMidiSetupChanged {
    _setupStream ??= _setupChannel.receiveBroadcastStream().cast<String>();
    return _setupStream;
  }

  @override
  void addVirtualDevice({String? name}) {
    _methodChannel.invokeMethod('addVirtualDevice', {"name": name});
  }

  @override
  void removeVirtualDevice({String? name}) {
    _methodChannel.invokeMethod('removeVirtualDevice', {"name": name});
  }

  @override
  Future<bool?> get isNetworkSessionEnabled {
    return _methodChannel.invokeMethod('isNetworkSessionEnabled');
  }

  @override
  void setNetworkSessionEnabled(bool enabled) {
    _methodChannel.invokeMethod('enableNetworkSession', enabled);
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
