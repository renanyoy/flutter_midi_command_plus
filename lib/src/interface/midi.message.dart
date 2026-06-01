import 'dart:typed_data';

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
class MidiMessage {
  final MidiMessageType type;
  const MidiMessage({required this.type});
  factory MidiMessage.from({required Uint8List data}) {
    final type = MidiMessageType.from(data[0]);
    switch (type) {
      case MidiMessageType.noteOff:
        return MidiMessageNoteOff.from(data: data);
      case MidiMessageType.noteOn:
        return MidiMessageNoteOn.from(data: data);
      case MidiMessageType.afterTouch:
        return MidiMessageAftertouch.from(data: data);
      case MidiMessageType.controlChange:
        return MidiMessageControlChange.from(data: data);
      case MidiMessageType.programChange:
        return MidiMessageProgramChange.from(data: data);
      case MidiMessageType.channelPressure:
        return MidiMessageChannelPressure.from(data: data);
      case MidiMessageType.pitchBend:
        return MidiMessagePitch.from(data: data);
      case MidiMessageType.sysExStart:
        return MidiMessageSysEx.from(data: data);
      case MidiMessageType.mtcQuaterFrame:
        return MidiMessageMtcQuaterFrame.from(data: data);
      case MidiMessageType.songPosition:
        return MidiMessageSongPosition.from(data: data);
      case MidiMessageType.songSelect:
        return MidiMessageSongSelect.from(data: data);
      case MidiMessageType.tuningRequested:
        return MidiMessageTuneRequested.from(data: data);
      case MidiMessageType.clock:
        return MidiMessageClock.from(data: data);
      case MidiMessageType.tick:
        return MidiMessageTick.from(data: data);
      case MidiMessageType.start:
        return MidiMessageStart.from(data: data);
      case MidiMessageType.midiContinue:
        return MidiMessageContinue.from(data: data);
      case MidiMessageType.stop:
        return MidiMessageStop.from(data: data);
      case MidiMessageType.activeSense:
        return MidiMessageActiveSense.from(data: data);
      case MidiMessageType.reset:
        return MidiMessageReset.from(data: data);
      default:
        throw Exception('Invalid MidiMessageType: $type');
    }
  }
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessage(type: $type)';
  String get description => 'Message: $type';
  String get key => '$type';

  static String keyFrom(
      {required MidiMessageType type,
      required int channel,
      required int number}) {
    return '$type.$channel.$number';
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
class MidiIOChannelMessage extends MidiMessage {
  final int channel;
  const MidiIOChannelMessage({required super.type, required this.channel});
  @override
  Uint8List get data => Uint8List.fromList([type.value | channel]);
  @override
  String toString() => 'MidiIOChannelMessage(type: $type, channel: $channel)';
  String get channelName =>
      channel < 9 ? 'Channel  ${channel + 1}' : 'Channel ${channel + 1}';
  @override
  String get description => '$channelName: $type';
  @override
  String get key => '$type.$channel';
}

/////////////////////////////////////////////////////////////////////////////////////////////////
class MidiMessageNote extends MidiIOChannelMessage {
  final int note;
  final int velocity;
  const MidiMessageNote(
      {required super.channel,
      required this.note,
      required this.velocity,
      required super.type});
  @override
  Uint8List get data =>
      Uint8List.fromList([type.value | channel, note, velocity]);
  @override
  String toString() =>
      'MidiMessageNoteOn(channel: $channel, note: $note, velocity: $velocity)';
  @override
  String get description =>
      '$channelName: Note On/Off ${midiNoteName(note)} $velocity';
  @override
  String get key => '$type.$channel.$note';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMessageNote &&
          type == other.type &&
          channel == other.channel &&
          note == other.note &&
          velocity == other.velocity;
  @override
  int get hashCode =>
      type.hashCode ^ channel.hashCode ^ note.hashCode ^ velocity.hashCode;
}

class MidiMessageNoteOn extends MidiMessageNote {
  const MidiMessageNoteOn({
    required super.channel,
    required super.note,
    required super.velocity,
    super.type = MidiMessageType.noteOn,
  });
  factory MidiMessageNoteOn.from({required Uint8List data}) {
    final note = data[1];
    final velocity = data[2];
    return MidiMessageNoteOn(
        channel: data[0] & 0xf, note: note, velocity: velocity);
  }
  @override
  String toString() =>
      'MidiMessageNoteOn(channel: $channel, note: $note, velocity: $velocity)';
  @override
  String get description =>
      '$channelName: Note On ${midiNoteName(note)} $velocity';
}

class MidiMessageNoteOff extends MidiMessageNote {
  const MidiMessageNoteOff({
    required super.channel,
    required super.note,
    required super.velocity,
    super.type = MidiMessageType.noteOff,
  });
  factory MidiMessageNoteOff.from({required Uint8List data}) {
    final note = data[1];
    final velocity = data[2];
    return MidiMessageNoteOff(
        channel: data[0] & 0xf, note: note, velocity: velocity);
  }
  @override
  String toString() =>
      'MidiMessageNoteOff(channel: $channel, note: $note, velocity: $velocity)';
  @override
  String get description =>
      '$channelName: Note Off ${midiNoteName(note)} $velocity';
}

class MidiMessageAftertouch extends MidiIOChannelMessage {
  final int note;
  final int pressure;
  const MidiMessageAftertouch({
    required super.channel,
    required this.note,
    required this.pressure,
    super.type = MidiMessageType.afterTouch,
  });
  factory MidiMessageAftertouch.from({required Uint8List data}) {
    final note = data[1];
    final pressure = data[2];
    return MidiMessageAftertouch(
        channel: data[0] & 0xf, note: note, pressure: pressure);
  }
  @override
  Uint8List get data =>
      Uint8List.fromList([type.value | channel, note, pressure]);
  @override
  String toString() =>
      'MidiMessageAftertouch(channel: $channel, note: $note, pressure: $pressure)';
  @override
  String get description =>
      '$channelName: Note On/Off ${midiNoteName(note)} $pressure';

  @override
  String get key => '$type.$channel.$note';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMessageAftertouch &&
          type == other.type &&
          channel == other.channel &&
          note == other.note &&
          pressure == other.pressure;
  @override
  int get hashCode =>
      type.hashCode ^ channel.hashCode ^ note.hashCode ^ pressure.hashCode;
}

class MidiMessageControlChange extends MidiIOChannelMessage {
  final int control;
  final int value;
  const MidiMessageControlChange({
    required super.channel,
    required this.control,
    required this.value,
    super.type = MidiMessageType.controlChange,
  });
  factory MidiMessageControlChange.from({required Uint8List data}) {
    final control = data[1];
    final value = data[2];
    return MidiMessageControlChange(
        channel: data[0] & 0xf, control: control, value: value);
  }
  @override
  Uint8List get data =>
      Uint8List.fromList([type.value | channel, control, value]);
  @override
  String toString() =>
      'MidiMessageControlChange(channel: $channel, control: $control, value: $value)';
  @override
  String get description => '$channelName: Control Change $control $value';
  @override
  String get key => '$type.$channel.$control';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMessageControlChange &&
          type == other.type &&
          channel == other.channel &&
          control == other.control &&
          value == other.value;
  @override
  int get hashCode =>
      type.hashCode ^ channel.hashCode ^ control.hashCode ^ value.hashCode;
}

class MidiMessageProgramChange extends MidiIOChannelMessage {
  final int program;
  const MidiMessageProgramChange({
    required super.channel,
    required this.program,
    super.type = MidiMessageType.programChange,
  });
  factory MidiMessageProgramChange.from({required Uint8List data}) {
    final program = data[1];
    return MidiMessageProgramChange(channel: data[0] & 0xf, program: program);
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value | channel, program]);
  @override
  String toString() =>
      'MidiMessageProgramChange(channel: $channel, program: $program)';
  @override
  String get description => '$channelName: Program Change $program';
  @override
  String get key => '$type.$channel';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMessageProgramChange &&
          type == other.type &&
          channel == other.channel &&
          program == other.program;
  @override
  int get hashCode => type.hashCode ^ channel.hashCode ^ program.hashCode;
}

class MidiMessageChannelPressure extends MidiIOChannelMessage {
  final int pressure;
  const MidiMessageChannelPressure({
    required super.channel,
    required this.pressure,
    super.type = MidiMessageType.channelPressure,
  });
  factory MidiMessageChannelPressure.from({required Uint8List data}) {
    final pressure = data[1];
    return MidiMessageChannelPressure(
        channel: data[0] & 0xf, pressure: pressure);
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value | channel, pressure]);
  @override
  String toString() =>
      'MidiMessageChannelPressure(channel: $channel, pressure: $pressure)';
  @override
  String get description => '$channelName: Channel Pressure $pressure';
  @override
  String get key => '$type.$channel';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMessageChannelPressure &&
          type == other.type &&
          channel == other.channel &&
          pressure == other.pressure;
  @override
  int get hashCode => type.hashCode ^ channel.hashCode ^ pressure.hashCode;
}

class MidiMessagePitch extends MidiIOChannelMessage {
  final int pitch;
  const MidiMessagePitch({
    required super.channel,
    required this.pitch,
    super.type = MidiMessageType.pitchBend,
  });
  factory MidiMessagePitch.from({required Uint8List data}) {
    final pitch = data[1];
    return MidiMessagePitch(channel: data[0] & 0xf, pitch: pitch);
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value | channel, pitch]);
  @override
  String toString() => 'MidiMessagePitch(channel: $channel, pitch: $pitch)';
  @override
  String get description => '$channelName: Pitch Bend $pitch';
  @override
  String get key => '$type.$channel';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMessagePitch &&
          type == other.type &&
          channel == other.channel &&
          pitch == other.pitch;
  @override
  int get hashCode => type.hashCode ^ channel.hashCode ^ pitch.hashCode;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
class MidiIOSystemMessage extends MidiMessage {
  const MidiIOSystemMessage({required super.type});
}

/////////////////////////////////////////////////////////////////////////////////////////////////
class MidiMessageSysEx extends MidiIOSystemMessage {
  final Uint8List sysex;
  const MidiMessageSysEx({
    required super.type,
    required this.sysex,
  });
  factory MidiMessageSysEx.from({required Uint8List data}) {
    return MidiMessageSysEx(
        type: MidiMessageType.sysExStart,
        sysex: data.sublist(1, data.length - 1));
  }
  @override
  Uint8List get data => Uint8List.fromList([
        MidiMessageType.sysExStart.value,
        ...sysex,
        MidiMessageType.sysExEnd.value
      ]);
  @override
  String toString() => 'MidiMessageSysEx(data: $data)';
  @override
  String get description => 'SysEx: $data';
}

class MidiMessageMtcQuaterFrame extends MidiIOSystemMessage {
  final int value;
  const MidiMessageMtcQuaterFrame({
    required this.value,
    super.type = MidiMessageType.mtcQuaterFrame,
  });
  factory MidiMessageMtcQuaterFrame.from({required Uint8List data}) {
    final value = data[1];
    return MidiMessageMtcQuaterFrame(value: value);
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value, value]);
  @override
  String toString() => 'MidiMessageMtcQuaterFrame(value: $value)';
  @override
  String get description => 'MtcQuaterFrame: $value';
}

class MidiMessageSongPosition extends MidiIOSystemMessage {
  final int position;
  const MidiMessageSongPosition({
    required this.position,
    super.type = MidiMessageType.songPosition,
  });
  factory MidiMessageSongPosition.from({required Uint8List data}) {
    final position = data[1] | (data[2] << 7);
    return MidiMessageSongPosition(position: position);
  }
  @override
  Uint8List get data =>
      Uint8List.fromList([type.value, position & 0x7f, (position >> 7) & 0x7f]);
  @override
  String toString() => 'MidiMessageSongPosition(position: $position)';
  @override
  String get description => 'SongPosition: $position';
}

class MidiMessageSongSelect extends MidiIOSystemMessage {
  final int song;
  const MidiMessageSongSelect({
    required this.song,
    super.type = MidiMessageType.songSelect,
  });
  factory MidiMessageSongSelect.from({required Uint8List data}) {
    final song = data[1];
    return MidiMessageSongSelect(song: song);
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value, song]);
  @override
  String toString() => 'MidiMessageSongSelect(song: $song)';
  @override
  String get description => 'SongSelect: $song';
}

class MidiMessageTuneRequested extends MidiIOSystemMessage {
  const MidiMessageTuneRequested({
    super.type = MidiMessageType.tuningRequested,
  });
  factory MidiMessageTuneRequested.from({required Uint8List data}) {
    return const MidiMessageTuneRequested();
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessageTuneRequested()';
  @override
  String get description => 'TuneRequested';
}

class MidiMessageClock extends MidiIOSystemMessage {
  const MidiMessageClock({
    super.type = MidiMessageType.clock,
  });
  factory MidiMessageClock.from({required Uint8List data}) {
    return const MidiMessageClock();
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessageClock()';
  @override
  String get description => 'Clock';
}

class MidiMessageTick extends MidiIOSystemMessage {
  const MidiMessageTick({
    super.type = MidiMessageType.tick,
  });
  factory MidiMessageTick.from({required Uint8List data}) {
    return const MidiMessageTick();
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessageTick()';
  @override
  String get description => 'Tick';
}

class MidiMessageStart extends MidiIOSystemMessage {
  const MidiMessageStart({
    super.type = MidiMessageType.start,
  });
  factory MidiMessageStart.from({required Uint8List data}) {
    return const MidiMessageStart();
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessageStart()';
  @override
  String get description => 'Start';
}

class MidiMessageContinue extends MidiIOSystemMessage {
  const MidiMessageContinue({
    super.type = MidiMessageType.midiContinue,
  });
  factory MidiMessageContinue.from({required Uint8List data}) {
    return const MidiMessageContinue();
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessageContinue()';
  @override
  String get description => 'Continue';
}

class MidiMessageStop extends MidiIOSystemMessage {
  const MidiMessageStop({
    super.type = MidiMessageType.stop,
  });
  factory MidiMessageStop.from({required Uint8List data}) {
    return const MidiMessageStop();
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessageStop()';
  @override
  String get description => 'Stop';
}

class MidiMessageActiveSense extends MidiIOSystemMessage {
  const MidiMessageActiveSense({
    super.type = MidiMessageType.activeSense,
  });
  factory MidiMessageActiveSense.from({required Uint8List data}) {
    return const MidiMessageActiveSense();
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessageActiveSense()';
  @override
  String get description => 'ActiveSense';
}

class MidiMessageReset extends MidiIOSystemMessage {
  const MidiMessageReset({
    super.type = MidiMessageType.reset,
  });
  factory MidiMessageReset.from({required Uint8List data}) {
    return const MidiMessageReset();
  }
  @override
  Uint8List get data => Uint8List.fromList([type.value]);
  @override
  String toString() => 'MidiMessageReset()';
  @override
  String get description => 'Reset';
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
// https://medium.com/@keybaudio/understanding-midi-messages-a1d1dba0296e
enum MidiMessageType {
  // channel messages
  noteOff(0x80),
  noteOn(0x90),
  afterTouch(0xa0),
  controlChange(0xb0),
  programChange(0xc0),
  channelPressure(0xd0),
  pitchBend(0xe0),
  system(0xf0),
  // system messages
  sysExStart(0xF0), // Start of SysEx stream
  sysExEnd(0xF7), // End of SysEx stream
  mtcQuaterFrame(0xF1), // MTC quarter frame time code
  songPosition(0xF2), // Ask slave to position playback cue
  songSelect(0xF3), // Select a certain song and cue to beginning
  tuningRequested(0xF6), // Being asked to self-tune
  clock(0xF8), // sync with a tempo (24 clocks per quarter note)
  tick(0xF9), // Being kept in sync with a tick (every 10ms)
  start(0xFA), // Master asking for playback from the beginning
  midiContinue(0xFB), // Master asked that we continue playback from cue
  stop(0xFC), // Master asked to stop playback and retain cue point
  activeSense(0xFE), // Keepalive data to let us know things are still connected
  reset(0xFF); // Reset to default, no keys pressed, cue to beginning

  final int value;
  const MidiMessageType(this.value);

  static MidiMessageType from(int value) {
    switch (value & 0xf0) {
      case 0x80:
        return MidiMessageType.noteOff;
      case 0x90:
        return MidiMessageType.noteOn;
      case 0xa0:
        return MidiMessageType.afterTouch;
      case 0xb0:
        return MidiMessageType.controlChange;
      case 0xc0:
        return MidiMessageType.programChange;
      case 0xd0:
        return MidiMessageType.channelPressure;
      case 0xe0:
        return MidiMessageType.pitchBend;
      case 0xf0:
        return fromSysEx(value);
      default:
        throw Exception('Invalid MidiMessageType value: $value');
    }
  }

  static MidiMessageType fromSysEx(int value) {
    switch (value) {
      case 0xF0:
        return MidiMessageType.sysExStart;
      case 0xF7:
        return MidiMessageType.sysExEnd;
      case 0xF1:
        return MidiMessageType.mtcQuaterFrame;
      case 0xF2:
        return MidiMessageType.songPosition;
      case 0xF3:
        return MidiMessageType.songSelect;
      case 0xF6:
        return MidiMessageType.tuningRequested;
      case 0xF8:
        return MidiMessageType.clock;
      case 0xF9:
        return MidiMessageType.tick;
      case 0xFA:
        return MidiMessageType.start;
      case 0xFB:
        return MidiMessageType.midiContinue;
      case 0xFC:
        return MidiMessageType.stop;
      case 0xFE:
        return MidiMessageType.activeSense;
      case 0xFF:
        return MidiMessageType.reset;
      default:
        throw Exception('Invalid MidiMessageType value: $value');
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
String midiNoteName(int note) {
  const noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];
  final octave = (note / 12).floor() - 1;
  final noteName = noteNames[note % 12];
  return '$noteName$octave';
}
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

