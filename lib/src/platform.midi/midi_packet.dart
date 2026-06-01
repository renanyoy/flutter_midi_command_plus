// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MidiPacket extends MidiPort {
  Uint8List data;
  int? timestamp;
  MidiPacket({
    required super.deviceId,
    required super.port,
    required this.data,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'port': port,
      'data': data,
      'timestamp': timestamp,
    };
  }

  factory MidiPacket.fromMap(Map<String, dynamic> map) {
    return MidiPacket(
      deviceId: map['deviceId'] as String,
      port: map['port'] as int,
      data: map['data'],
      timestamp: map['timestamp'] as int?,
    );
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
