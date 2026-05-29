// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MidiPacket {
  String deviceId;
  int port;
  Uint32List data;
  int? timestamp;
  MidiPacket({
    required this.deviceId,
    required this.port,
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
