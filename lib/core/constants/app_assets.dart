class AppAssets {
  // Premium 3D characters (generated for the QuizBaaz visual system).
  static const String heroBoy = 'assets/images/characters/quizbaaz_mascot_boy.png';
  static const String heroGirl = 'assets/images/characters/quizbaaz_mascot_girl.png';
  static const String championBoy = 'assets/images/characters/quizbaaz_champion.png';
  static const String quizChampion = 'assets/images/characters/quizbaaz_quiz_guide.png';
  static const String battleDuo = 'assets/images/characters/quizbaaz_battle_duo.png';
  static const String rewardGirl = 'assets/images/characters/quizbaaz_reward_girl.png';

  // Premium profile avatars.
  static const String maleAvatar = 'assets/images/avatars/quizbaaz_avatar_boy.png';
  static const String femaleAvatar = 'assets/images/avatars/quizbaaz_avatar_girl.png';
  static const String userAvatarBoy = maleAvatar; // Backwards compatibility.

  // Existing glossy action icons are still used by secondary screens.
  static const String streakFire = 'assets/icons/streak_fire_3d.png';
  static const String coinGem = 'assets/icons/coin_and_gem_3d.png';
  static const String chapterQuiz = 'assets/icons/chapter_quiz_3d.png';
  static const String practiceTarget = 'assets/icons/practice_target_3d.png';
  static const String battleSwords = 'assets/icons/battle_swords_3d.png';
  static const String giftBox = 'assets/icons/gift_box_3d.png';
  static const String shopStall = 'assets/icons/shop_stall_3d.png';

  // JSON question banks (authored content, cached in Hive after first read).
  // Ranking data is NEVER bundled — it comes from Firestore via Hive.
  static const String jsonChapters = 'assets/data/chapters_list.json';
  static const String jsonDailyQuiz = 'assets/data/daily_quiz.json';
}
