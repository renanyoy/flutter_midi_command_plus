import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';
import 'package:bb.flutter/bb.dart';

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
class MidiDeviceView extends StatelessWidget {
  final MidiDevice device;
  final VoidCallback? onRemove;
  const MidiDeviceView({super.key, required this.device, this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text('${device.name} - ${device.id}'),
              Text('${device.type}'),
              Text('inputs: ${device.inputs}'),
              Text('outputs: ${device.outputs}'),
            ],
          ),
        ),
        if (device.type == .virtual)
          IconButton(onPressed: onRemove, icon: Icon(Icons.delete)),
      ],
    );
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
