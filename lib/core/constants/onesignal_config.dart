/// OneSignal + FCM configuration for QuizBaaz.
///
/// ⚠️ HOW TO GO LIVE (one-time, free OneSignal account):
///
/// 1. Open https://onesignal.com → New App/Website → name it **QuizBaaz**.
/// 2. Platform **Google Android (FCM)**:
///    Firebase console (project `quizbaaz-740bd`) → Project settings →
///    **Service accounts** → Generate new private key. Upload that JSON
///    in OneSignal → Settings → Push & In-App → Google Android (FCM).
///    **Do not commit the JSON.** Delete the download when OneSignal has it.
/// 3. Copy the 36-character **App ID** from Settings → Keys & IDs.
/// 4. Paste it into [appId] below and rebuild.
/// 5. Send a test push from the OneSignal dashboard to this device.
///
/// Until [appId] is pasted, OneSignal stays off. Local 19:00 Daily Quiz
/// reminders (docs/15) still work. See docs/16 for iOS APNs and click payloads.
class OneSignalConfig {
  OneSignalConfig._();

  /// OneSignal App ID (UUID). Empty = SDK does not initialise.
  static const String appId = '';

  static bool get isConfigured =>
      appId.length == 36 && !appId.contains('YOUR_');
}
