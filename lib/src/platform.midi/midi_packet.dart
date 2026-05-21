import 'dart:typed_data';

import 'midi_port.dart';


class MidiPacket {
  int timestamp;
  Uint8List data;
  MidiPort port;


  MidiPacket(this.data, this.timestamp, this.port);

  Map<String, Object> get toDictionary {
    return {
      "data": data,
      "timestamp": timestamp,
      "sender": port.toDictionary
    };
  }
}
