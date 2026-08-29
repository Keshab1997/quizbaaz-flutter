/// Pure scoring rules for 1-vs-1 battles — no Flutter dependencies.
///
/// ## Formula
///
/// ```text
/// correct answer  →  base (10)
///                  + speed bonus  (up to 10 — scaled by time remaining)
///                  + first bonus  (3 — locked in before the opponent)
///                  + streak bonus (2 × streak, capped)
/// wrong / timeout →  0
/// ```
///
/// The speed bonus is *continuous*: answering instantly pays the full bonus
/// and answering with the last second pays almost nothing, so a player is
/// always rewarded for speed — even when the opponent has already answered
/// (the flat "first" bonus alone kept nobody racing the clock).
class BattleScoring {
  const BattleScoring._();

  /// The four components of one answer.
  /// `total = base + speedBonus + firstBonus + streakBonus`
  static ({
    int base,
    int speedBonus,
    int firstBonus,
    int streakBonus,
  }) compute({
    required bool correct,
    required int remainingMs, // ms left on the question clock when answered
    required int questionDurationMs, // full question window in ms
    required bool answeredBeforeOpponent, // true = this side locked in first
    required int streak, // consecutive correct count before this answer
    required int basePoints, // default 10
    required int maxSpeedBonus, // default 10 — full bonus for an instant answer
    required int firstBonus, // default 3 — flat race bonus
    required int streakBonusPerStreak, // default 2
    int maxStreakBonus = 10, // cap so long battles can't snowball forever
  }) {
    if (!correct) {
      return (base: 0, speedBonus: 0, firstBonus: 0, streakBonus: 0);
    }

    // Time-scaled speed bonus: instant → full bonus, last second → ~0.
    var speed = 0;
    if (questionDurationMs > 0 && remainingMs > 0 && maxSpeedBonus > 0) {
      speed = (maxSpeedBonus * remainingMs / questionDurationMs).round();
      if (speed < 0) speed = 0;
      if (speed > maxSpeedBonus) speed = maxSpeedBonus;
    }

    final first = answeredBeforeOpponent ? firstBonus : 0;
    final streakB = streak >= 1
        ? (streak * streakBonusPerStreak).clamp(0, maxStreakBonus)
        : 0;

    return (
      base: basePoints,
      speedBonus: speed,
      firstBonus: first,
      streakBonus: streakB,
    );
  }

  /// Total for a component tuple.
  static int total(
    ({int base, int speedBonus, int firstBonus, int streakBonus}) parts,
  ) =>
      parts.base + parts.speedBonus + parts.firstBonus + parts.streakBonus;

  /// Human-readable breakdown, e.g. `10 + 8 + 3 + 4`
  static String breakdown(
    ({int base, int speedBonus, int firstBonus, int streakBonus}) parts,
  ) =>
      '${parts.base} + ${parts.speedBonus} + ${parts.firstBonus} + '
      '${parts.streakBonus}';
}
