import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SessionRetentionService {
  const SessionRetentionService({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const _channelName = 'com.zarathu.seil/session_retention';

  final MethodChannel _channel;

  Future<void> start({
    required Duration duration,
    required int activeSessions,
  }) async {
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('start', {
        'durationSeconds': duration.inSeconds,
        'activeSessions': activeSessions,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> stop() async {
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
