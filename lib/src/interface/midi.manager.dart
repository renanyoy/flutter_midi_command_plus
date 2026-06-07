// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:bb_dart/bb_dart.dart';
import 'package:collection/collection.dart';

import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MidiManager {
  MidiManager();
  late final MidiCommand command;
  final onBluetoothStateChanged = Event<BluetoothState>();
  final onSetupChanged = Event<String>();
  final onDevicesChanged = Event<List<MidiDevice>>();
  final onDeviceAdded = Event<MidiDevice>();
  final onDeviceRemoved = Event<MidiDevice>();
  final onMidiPacket = Event<MidiPacket>();
  final Map<MidiPort, Event<MidiMessage>> _onMidiMessage = {};
  StreamSubscription? _stateSub;
  StreamSubscription? _setupSub;
  final List<MidiDevice> devices = [];

  Future<void> initialize({bool useBluetooth = true}) async {
    command = MidiCommand();
    if (useBluetooth) {
      await command.startBluetoothCentral();
      _stateSub = command.onBluetoothStateChanged.listen((state) async {
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
    _setupSub = command.onMidiSetupChanged?.listen((setup) async {
      Debug.info('setup: $setup');
      onSetupChanged.fire(setup);
      if (setup == 'setupChanged') {
        await updateDevices();
      }
    });
    command.onMidiDataReceived?.listen((packet) {
      onMidiPacket.fire(packet);
      if (_onMidiMessage.containsKey(packet)) {
        final message = MidiMessage.from(data: packet.data);
        _onMidiMessage[packet]!.fire(message);
      }
    });
    updateDevices();
  }

  Event<MidiMessage> input(MidiPort port) {
    if (!_onMidiMessage.containsKey(port)) {
      _onMidiMessage[port] = Event<MidiMessage>();
    }
    return _onMidiMessage[port]!;
  }

  MidiOutput output(MidiPort port) => MidiOutput(command: command, port: port);

  void dispose() {
    for (final device in devices) {
      command.disconnectDevice(device);
    }
    _stateSub?.cancel();
    _setupSub?.cancel();
  }

  Future<void> updateDevices() async {
    final odevices = {...this.devices};
    final devices = {...(await command.devices ?? [])};
    final added = {...devices.where((d) => !odevices.contains(d))};
    final removed = {...odevices.where((d) => !devices.contains(d))};
    if (added.isNotEmpty || removed.isNotEmpty) {
      this.devices.clear();
      this.devices.addAll(devices);
      this.devices.sortBy((d) => d.name);
      for (final d in added) {
        if (!await command.deviceConnected(d)) {
          await command.connectDevice(d);
        }
        onDeviceAdded.fire(d);
      }
      for (final d in removed) {
        onDeviceRemoved.fire(d);
        for (int p = 0; p < d.inputs; p++) {
          final key = MidiPort(deviceId: d.id, port: p);
          _onMidiMessage[key]?.dispose();
          _onMidiMessage.remove(key);
        }
      }
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
class MidiOutput extends MidiPort {
  final MidiCommand command;
  MidiOutput({required this.command, required MidiPort port})
    : super(deviceId: port.deviceId, port: port.port);
  Future<void> write({required MidiMessage mesage, int? timeStamp}) async {
    //command.sendData(deviceId: deviceId, port: port, data: message.data, timestamp: timeStamp);
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
