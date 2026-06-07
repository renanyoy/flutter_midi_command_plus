import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MidiDeviceView extends StatefulWidget {
  final MidiManager manager;
  final MidiDevice device;
  final VoidCallback? onRemove;
  const MidiDeviceView({
    super.key,
    required this.device,
    this.onRemove,
    required this.manager,
  });
  @override
  State<MidiDeviceView> createState() => _MidiDeviceViewState();
}

class _MidiDeviceViewState extends State<MidiDeviceView> {
  final List<String> messages = [];
  final List<StreamSubscription> subs = [];
  @override
  void initState() {
    const maxMessages = 5;
    super.initState();
    final d = widget.device;
    for (int p = 0; p < d.inputs; p++) {
      final port = MidiPort(deviceId: d.id, port: p);
      subs.add(
        widget.manager.input(port).listen((message) {
          messages.add('$p: $message');
          final l = messages.length;
          if (l > maxMessages) {
            messages.removeRange(0, messages.length - maxMessages);
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  void unsubscribe() {
    for (final s in subs) {
      s.cancel();
    }
    subs.clear();
  }

  void subscribe() {
    const maxMessages = 5;
    final d = widget.device;
    for (int p = 0; p < d.inputs; p++) {
      final port = MidiPort(deviceId: d.id, port: p);
      subs.add(
        widget.manager.input(port).listen((message) {
          messages.add('$p: $message');
          final l = messages.length;
          if (l > maxMessages) {
            messages.removeRange(0, messages.length - maxMessages);
          }
        }),
      );
    }
  }

  @override
  void didUpdateWidget(covariant MidiDeviceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.device != widget.device) {
      unsubscribe();
      subscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text('${widget.device.name} - ${widget.device.id}'),
              Text('${widget.device.type}'),
              Text('inputs: ${widget.device.inputs}'),
              Text('outputs: ${widget.device.outputs}'),
              for(final m in messages)
              Text(m,style:TextTheme.of(context).bodySmall)
            ],
          ),
        ),
        if (widget.device.type == .virtual)
          IconButton(onPressed: widget.onRemove, icon: Icon(Icons.delete)),
      ],
    );
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
