import 'dart:async';
import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'method_channel_midi_command.dart';
import 'midi_device.dart';
import 'midi_packet.dart';
import 'midi_port.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
abstract class MidiCommandPlatform extends PlatformInterface {
  MidiCommandPlatform() : super(token: _token);
  static final Object _token = Object();
  static MidiCommandPlatform _instance = MethodChannelMidiCommand();

  static MidiCommandPlatform get instance => _instance;
  static set instance(MidiCommandPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<MidiDevice>?> get devices async {
    throw UnimplementedError('get devices has not been implemented.');
  }

  Future<void> startBluetoothCentral() async {
    throw UnimplementedError(
      'startBluetoothCentral() has not been implemented.',
    );
  }

  Stream<String>? get onBluetoothStateChanged {
    throw UnimplementedError(
      'get onBluetoothStateChanged has not been implemented.',
    );
  }

  Future<String> bluetoothState() async {
    throw UnimplementedError('bluetoothState() has not been implemented.');
  }

  Future<void> startScanningForBluetoothDevices() async {
    throw UnimplementedError(
      'startScanningForBluetoothDevices() has not been implemented.',
    );
  }

  void stopScanningForBluetoothDevices() {
    throw UnimplementedError(
      'stopScanningForBluetoothDevices() has not been implemented.',
    );
  }

  Future<void> connectToDevice(MidiDevice device, {List<MidiPort>? ports}) {
    throw UnimplementedError('connectToDevice() has not been implemented.');
  }

  void disconnectDevice(MidiDevice device) {
    throw UnimplementedError('disconnectDevice() has not been implemented.');
  }

  void teardown() {
    throw UnimplementedError('teardown() has not been implemented.');
  }

  void sendData(
    Uint8List data, {
    int? timestamp,
    String? deviceId,
    int? portId,
  }) {
    throw UnimplementedError('sendData() has not been implemented.');
  }

  Stream<MidiPacket>? get onMidiDataReceived {
    throw UnimplementedError(
      'get onMidiDataReceived has not been implemented.',
    );
  }

  Stream<String>? get onMidiSetupChanged {
    throw UnimplementedError(
      'get onMidiSetupChanged has not been implemented.',
    );
  }

  void addVirtualDevice({String? name}) {
    throw UnimplementedError('addVirtualDevice() has not been implemented.');
  }

  void removeVirtualDevice({String? name}) {
    throw UnimplementedError('removeVirtualDevice() has not been implemented.');
  }

  Future<bool?> get isNetworkSessionEnabled {
    throw UnimplementedError(
      'isNetworkSessionEnabled has not been implemented.',
    );
  }

  void setNetworkSessionEnabled(bool enabled) {
    throw UnimplementedError(
      'setNetworkSessionEnabled has not been implemented.',
    );
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
