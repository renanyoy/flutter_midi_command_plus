import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'flutter_midi_command_platform_interface.dart';
import 'midi_device.dart';
import 'midi_packet.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
const MethodChannel _methodChannel = MethodChannel(
  'plugins.aestesis.org/flutter_midi_command',
);
//////////////////////////////////////////////////////////////////////////////////////////////////////////
const EventChannel _rxChannel = EventChannel(
  'plugins.aestesis.org/flutter_midi_command/rx_channel',
);
//////////////////////////////////////////////////////////////////////////////////////////////////////////
const EventChannel _setupChannel = EventChannel(
  'plugins.aestesis.org/flutter_midi_command/setup_channel',
);
//////////////////////////////////////////////////////////////////////////////////////////////////////////
const EventChannel _bluetoothStateChannel = EventChannel(
  'plugins.aestesis.org/flutter_midi_command/bluetooth_central_state',
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
      var dev = MidiDevice.fromMap(map);
      return dev;
    }).toList();
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
  Future<bool> isDeviceConnected(MidiDevice device) async {
    return await _methodChannel.invokeMethod('deviceConnected', {
      "deviceId": device.id,
    });
  }

  @override
  Future<void> connectToDevice(MidiDevice device) {
    return _methodChannel.invokeMethod('connectToDevice', {
      "deviceId": device.id,
    });
  }

  @override
  void disconnectDevice(MidiDevice device) {
    _methodChannel.invokeMethod('disconnectDevice', {"deviceId": device.id});
  }

  @override
  void teardown() {
    _methodChannel.invokeMethod('teardown');
  }

  @override
  void sendData({
    required String deviceId,
    required int port,
    required Uint32List data,
    int? timestamp,
  }) {
    _methodChannel.invokeMethod('sendData', {
      "deviceId": deviceId,
      "port": port,
      "data": data,
      "timestamp": timestamp,
    });
  }

  @override
  Stream<MidiPacket>? get onMidiDataReceived {
    // print("get on midi data");
    _rxStream ??= _rxChannel.receiveBroadcastStream().map<MidiPacket>((m) {
      print('$m');
      if (m is! Map) throw Exception('wrong format');
      final mp = Map<String,dynamic>.from(m);
      //final mp = m.map((k, v) => MapEntry<String,dynamic>(k, v));
      return MidiPacket.fromMap(mp);
    });
    return _rxStream;
  }

  @override
  Stream<String>? get onMidiSetupChanged {
    _setupStream ??= _setupChannel.receiveBroadcastStream().cast<String>();
    return _setupStream;
  }

  @override
  Future<MidiDevice> addVirtualDevice({String? name}) async {
    return await _methodChannel.invokeMethod('addVirtualDevice', {
      "name": name,
    });
  }

  @override
  Future<void> removeVirtualDevice({String? deviceId}) async {
    await _methodChannel.invokeMethod('removeVirtualDevice', {
      "deviceId": deviceId,
    });
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
