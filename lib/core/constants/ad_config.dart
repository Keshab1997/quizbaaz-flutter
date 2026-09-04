/// AdMob configuration for QuizBaaz.
///
/// ⚠️ HOW TO GO LIVE (before publishing to Play Store):
///
/// 1. Create the "QuizBaaz" app in the AdMob console
///    (https://apps.admob.com) using the package name
///    `com.keshabstudios.quizbaaz`.
/// 2. Create one **Banner** ad unit and one **Interstitial** ad unit.
/// 3. Replace [appId] with your own (from the AdMob dashboard's
///    "App settings"), and [bannerAdUnitId] / [interstitialAdUnitId] with
///    the IDs shown next to each ad unit.
/// 4. Also replace `com.google.android.gms.ads.APPLICATION_ID` in
///    `android/app/src/main/AndroidManifest.xml` and
///    `GADApplicationIdentifier` in `ios/Runner/Info.plist`.
///
/// Until then the **official Google test IDs** below are used, which show
/// harmless test ads in every build.
class AdConfig {
  AdConfig._();

  /// Android/iOS App ID — currently the official Google *test* app ID.
  /// Replace with `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY` from AdMob.
  static const String appId = 'ca-app-pub-3940256099942544~3347511713';

  /// Official Google test banner ad unit (Android).
  /// Replace with your real banner ad unit ID from AdMob.
  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  /// Official Google test interstitial ad unit (Android).
  /// Replace with your real interstitial ad unit ID from AdMob.
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Show the interstitial after every N quiz completions (2 = every 2nd
  /// quiz). Keeps ads frequent enough to earn, but never spammy.
  static const int interstitialFrequency = 2;

  /// Hive meta key holding the quiz-completion counter for [interstitialFrequency].
  static const String quizCounterKey = 'ad_quiz_counter';
}
