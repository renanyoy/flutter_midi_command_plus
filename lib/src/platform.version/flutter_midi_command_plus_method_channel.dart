import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_midi_command_plus_platform_interface.dart';

/// An implementation of [FlutterMidiCommandPlusPlatform] that uses method channels.
class MethodChannelFlutterMidiCommandPlus extends FlutterMidiCommandPlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_midi_command_plus');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
