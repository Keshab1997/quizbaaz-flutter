/// User-facing links used across the app (Profile → About, share, etc.).
///
/// Keep these in sync with the hosted pages in the `privacy_policy` repo
/// (https://github.com/Keshab1997/privacy_policy) and the Play Store listing.
class AppLinks {
  AppLinks._();

  /// Hosted on `keshab1997.github.io/privacy_policy/` (GitHub Pages).
  static const String privacyPolicy =
      'https://keshab1997.github.io/privacy_policy/quizbaaz.html';

  static const String terms =
      'https://keshab1997.github.io/privacy_policy/quizbaaz-terms.html';

  /// Live only after the app is published to Google Play.
  static const String playStore =
      'https://play.google.com/store/apps/details?id=com.keshabstudios.quizbaaz';
}
