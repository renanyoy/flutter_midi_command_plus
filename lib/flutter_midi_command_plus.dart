
import 'flutter_midi_command_plus_platform_interface.dart';

class FlutterMidiCommandPlus {
  Future<String?> getPlatformVersion() {
    return FlutterMidiCommandPlusPlatform.instance.getPlatformVersion();
  }
}
