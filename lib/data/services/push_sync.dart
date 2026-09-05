import 'notification_service.dart';
import 'onesignal_service.dart';

/// One call site for "the notification setting / profile / language changed".
/// Local 19:00 reminders and OneSignal opt-in stay in lockstep.
class PushSync {
  PushSync._();

  static Future<void> syncFromHive() async {
    await NotificationService.instance.syncFromHive();
    await OneSignalService.instance.syncFromHive();
  }
}
