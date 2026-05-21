import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_midi_command_plus/flutter_midi_command_plus.dart';
import 'package:flutter_midi_command_plus/flutter_midi_command_plus_platform_interface.dart';
import 'package:flutter_midi_command_plus/flutter_midi_command_plus_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterMidiCommandPlusPlatform
    with MockPlatformInterfaceMixin
    implements FlutterMidiCommandPlusPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterMidiCommandPlusPlatform initialPlatform = FlutterMidiCommandPlusPlatform.instance;

  test('$MethodChannelFlutterMidiCommandPlus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterMidiCommandPlus>());
  });

  test('getPlatformVersion', () async {
    FlutterMidiCommandPlus flutterMidiCommandPlusPlugin = FlutterMidiCommandPlus();
    MockFlutterMidiCommandPlusPlatform fakePlatform = MockFlutterMidiCommandPlusPlatform();
    FlutterMidiCommandPlusPlatform.instance = fakePlatform;

    expect(await flutterMidiCommandPlusPlugin.getPlatformVersion(), '42');
  });
}
