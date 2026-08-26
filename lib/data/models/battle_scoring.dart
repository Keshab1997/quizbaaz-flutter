/// Pure scoring rules for 1-vs-1 battles — no Flutter dependencies.
///
/// ## Formula
///
/// ```text
/// correct answer  →  base (10) + speed bonus (5 if before opponent) + streak bonus (2 per streak)
/// wrong / timeout →  0
/// ```
class BattleScoring {
  const BattleScoring._();

  /// The three components of one answer.
  /// `total = base + speedBonus + streakBonus`
  static ({int base, int speedBonus, int streakBonus}) compute({
    required bool correct,
    required bool answeredBeforeOpponent, // true = player answered first
    required int streak,                  // consecutive correct count before this answer
    required int basePoints,              // default 10
    required int speedBonus,              // default 5
    required int streakBonusPerStreak,    // default 2
  }) {
    if (!correct) return (base: 0, speedBonus: 0, streakBonus: 0);

    final sb = streak >= 1 ? (streak * streakBonusPerStreak) : 0;
    final spd = answeredBeforeOpponent ? speedBonus : 0;

    return (
      base: basePoints,
      speedBonus: spd,
      streakBonus: sb,
    );
  }

  /// Total for a component triple.
  static int total(({int base, int speedBonus, int streakBonus}) parts) =>
      parts.base + parts.speedBonus + parts.streakBonus;

  /// Human-readable breakdown, e.g. `10 + 5 + 4`
  static String breakdown(({int base, int speedBonus, int streakBonus}) parts) =>
      '${parts.base} + ${parts.speedBonus} + ${parts.streakBonus}';
}
