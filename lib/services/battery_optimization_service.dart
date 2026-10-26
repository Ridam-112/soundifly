import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('com.soundifly.soundifly/battery');

  /// Checks if the app is already exempted from Android battery optimizations (Doze mode)
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final res = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return res ?? false;
    } catch (e) {
      debugPrint('[BatteryOptimization] Check error: $e');
      return false;
    }
  }

  /// Prompts the Android system dialog to request exemption so music never stops with screen off
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('[BatteryOptimization] Request error: $e');
    }
  }
}
