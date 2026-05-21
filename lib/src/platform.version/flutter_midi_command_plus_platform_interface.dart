import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_midi_command_plus_method_channel.dart';

abstract class FlutterMidiCommandPlusPlatform extends PlatformInterface {
  /// Constructs a FlutterMidiCommandPlusPlatform.
  FlutterMidiCommandPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterMidiCommandPlusPlatform _instance = MethodChannelFlutterMidiCommandPlus();

  /// The default instance of [FlutterMidiCommandPlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterMidiCommandPlus].
  static FlutterMidiCommandPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterMidiCommandPlusPlatform] when
  /// they register themselves.
  static set instance(FlutterMidiCommandPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
