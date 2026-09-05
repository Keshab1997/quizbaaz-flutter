import 'package:flutter_test/flutter_test.dart';
import 'package:quizbaaz/core/constants/onesignal_config.dart';

void main() {
  test('OneSignal stays off until a real App ID is pasted', () {
    expect(OneSignalConfig.appId.contains('YOUR_'), isFalse);
    if (OneSignalConfig.appId.isEmpty) {
      expect(OneSignalConfig.isConfigured, isFalse);
    } else {
      expect(OneSignalConfig.appId, hasLength(36));
      expect(OneSignalConfig.isConfigured, isTrue);
    }
  });
}
