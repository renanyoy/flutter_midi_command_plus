// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:bb_dart/bb_dart.dart';
import 'package:collection/collection.dart';

import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MidiManager {
  MidiManager();
  final onBluetoothStateChanged = Event<BluetoothState>();
  final onSetupChanged = Event<String>();
  final onDevicesChanged = Event<List<MidiDevice>>();
  final onMidiData = Event<MidiPacket>();
  final Map<MidiPort, Event<MidiMessage>> onMidiMessage = {};
  late final MidiCommand command;
  StreamSubscription? stateSub;
  StreamSubscription? setupSub;
  final List<MidiDevice> devices = [];

  Future<void> initialize({bool useBluetooth = true}) async {
    command = MidiCommand();
    if (useBluetooth) {
      await command.startBluetoothCentral();
      stateSub = command.onBluetoothStateChanged.listen((state) async {
        Debug.info('state: $state');
        switch (state) {
          case BluetoothState.poweredOn:
          case BluetoothState.poweredOff:
          case BluetoothState.resetting:
          case BluetoothState.unauthorized:
          case BluetoothState.unknown:
          case BluetoothState.unsupported:
          case BluetoothState.other:
            break;
        }
        onBluetoothStateChanged.fire(state);
      });
    }
    setupSub = command.onMidiSetupChanged?.listen((setup) async {
      Debug.info('setup: $setup');
      onSetupChanged.fire(setup);
      if (setup == 'setupChanged') {
        await updateDevices();
      }
    });
    command.onMidiDataReceived?.listen((packet) {
      onMidiData.fire(packet);
      if (onMidiMessage.containsKey(packet)) {
        final message = MidiMessage.from(data: packet.data);
        onMidiMessage[packet]!.fire(message);
      }
    });
    updateDevices();
  }

  Event<MidiMessage> events({required String deviceId, required int port}) {
    final key = MidiPort(deviceId: deviceId, port: port);
    if (!onMidiMessage.containsKey(key)) {
      onMidiMessage[key] = Event<MidiMessage>();
    }  
    return onMidiMessage[key]!;
  }

  void dispose() {
    for (final device in devices) {
      command.disconnectDevice(device);
    }
    stateSub?.cancel();
    setupSub?.cancel();
  }

  Future<void> updateDevices() async {
    final odevices = {...this.devices};
    final devices = {...(await command.devices ?? [])};
    for (final d in devices) {
      if (!await command.deviceConnected(d)) {
        await command.connectDevice(d);
      }
    }
    if (!DeepCollectionEquality().equals(odevices, {...devices})) {
      this.devices.clear();
      this.devices.addAll(devices);
      this.devices.sortBy((d) => d.name);
      onDevicesChanged.fire(this.devices);
    }
  }

  Future<void> startBluetouthScanning() async {
    await command.startScanningForBluetoothDevices();
  }

  void stopBluetouthScanning() {
    command.stopScanningForBluetoothDevices();
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
