import 'dart:async';

import 'package:bb_dart/bb_dart.dart';
import 'package:collection/collection.dart';
import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MidiManager {
  MidiManager();
  final onMidiData = Event<MidiPacket>();
  final onBluetoothStateChanged = Event<BluetoothState>();
  final onSetupChanged = Event<String>();
  final onDevicesChanged = Event<List<MidiDevice>>();
  late final MidiCommand mc;
  StreamSubscription? stateSub;
  StreamSubscription? setupSub;
  final List<MidiDevice> devices = [];

  Future<void> initialize({bool useBluetooth = true}) async {
    mc = MidiCommand();
    if (useBluetooth) {
      await mc.startBluetoothCentral();
      stateSub = mc.onBluetoothStateChanged.listen((state) async {
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
        await updateDevices();
      });
    }
    setupSub = mc.onMidiSetupChanged?.listen((setup) async {
      Debug.info('setup: $setup');
      onSetupChanged.fire(setup);
      await updateDevices();
    });
    mc.onMidiDataReceived?.listen((packet) {
      onMidiData.fire(packet);
      // TODO:      CCMessage
    });
    updateDevices();
  }

  void dispose() {
    for (final device in devices) {
      if (device.connected) {
        mc.disconnectDevice(device);
      }
    }
    stateSub?.cancel();
    setupSub?.cancel();
  }

  Future<void> updateDevices() async {
    final odevices = {...devices};
    final devscan = {...(await mc.devices ?? [])};
    // add added
    for (final device in devscan) {
      if (!devices.contains(device)) {
        if (!device.connected) {
          try {
            await mc.connectToDevice(device);
            Debug.info('connected device ${device.name}');
          } catch (_) {}
          device.connected = true;
        }
        Debug.info('added device ${device.name}');
        devices.add(device);
      }
    }
    // remove removed
    devices.removeWhere(
      (device) => !devscan.contains(device)
    );
    devices.sortBy((d) => d.name);
    if (!DeepCollectionEquality().equals(odevices, {...devices})) {
      onDevicesChanged.fire(devices);
    }
  }

  Future<void> startBluetouthScanning() async {
    await mc.startScanningForBluetoothDevices();
  }

  void stopBluetouthScanning() {
    mc.stopScanningForBluetoothDevices();
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
