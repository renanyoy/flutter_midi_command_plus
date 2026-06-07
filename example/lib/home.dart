import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';
import 'package:bb.flutter/bb.dart';

import 'device.dart';

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
  late final StreamSubscription changedSub;
  final Map<MidiPort, List<MidiMessage>> messages = {};
  @override
  void initState() {
    super.initState();
    changedSub = mm.onDevicesChanged.listen((d) {
      if (mounted) setState(() {});
    });
    mm.initialize(useBluetooth: false);
  }

  @override
  void dispose() {
    changedSub.cancel();
    mm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: .start,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.green),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    mm.command.addVirtualDevice();
                  },
                  child: Text('+Virtual'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    SizedBox(height: 20),
                    ...BB.separator(
                      items: mm.devices.map(
                        (d) => MidiDeviceView(
                          key: Key(d.id),
                          manager: mm,
                          device: d,
                          onRemove: () {
                            mm.command.removeVirtualDevice(deviceId: d.id);
                          },
                        ),
                      ),
                      separatorBuilder: () => SizedBox(height: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
