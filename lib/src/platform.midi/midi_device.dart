//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class MidiDevice {
  String type;
  String id;
  String name;
  int inputs;
  int outputs;
  MidiDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.inputs,
    required this.outputs,
  });
  @override
  bool operator ==(Object other) => other is MidiDevice && id == other.id;
  @override
  int get hashCode => id.hashCode;
  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'id': id,
    'type': type,
    'inputs': inputs,
    'outputs': outputs,
  };
  factory MidiDevice.fromMap(Map<String, dynamic> map) => MidiDevice(
    name: map['name'] as String,
    id: map['id'] as String,
    type: map['type'] as String,
    inputs: map['inputs'] as int,
    outputs: map['outputs'] as int,
  );
}
////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
