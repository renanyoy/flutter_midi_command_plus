import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';
import 'package:bb.flutter/bb.dart';
import 'package:flutter_midi_command_plus_example/manager.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class _HomeState extends State<Home> {
  late final MidiManager mm = MidiManager();
  late final StreamSubscription devicesSub;
  @override
  void initState() {
    super.initState();
    devicesSub = mm.onDevicesChanged.listen((d) {
      if (mounted) setState(() {});
    });
    mm.initialize(useBluetooth: false);
  }

  @override
  void dispose() {
    devicesSub.cancel();
    mm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            ...BB.separator(
              items: mm.devices.map((d) => MidiDeviceView(device: d)),
              separatorBuilder: () => SizedBox(height: 10),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MidiDeviceView extends StatelessWidget {
  final MidiDevice device;
  const MidiDeviceView({super.key, required this.device});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text('${device.name} - ${device.id}'),
        Text(device.connected ? '- connected' : '- disconnected'),
        ...device.inputPorts.map((p) => Text('${p.type.name} - ${p.id}')),
        ...device.outputPorts.map((p) => Text('${p.type.name} - ${p.id}')),
      ],
    );
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
