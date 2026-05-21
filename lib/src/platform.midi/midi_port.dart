enum MidiPortType { input, output }

class MidiPort {
  final String deviceId;
  final int id;
  final MidiPortType type;
  final bool connected;
  const MidiPort(this.deviceId, this.id, this.type, {this.connected = false});
  Map<String, Object> get toDictionary {
    return {
      "device": deviceId,
      "id": id,
      "type": type.name,
      "connected": connected,
    };
  }
}
