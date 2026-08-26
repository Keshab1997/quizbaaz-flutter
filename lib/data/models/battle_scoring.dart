/// Pure scoring rules for 1-vs-1 battles — no Flutter dependencies, so the
/// fairness of the scoreboard is unit-testable.
///
/// ## Formula (both player and bot pay the same price)
///
/// ```text
/// correct answer  →  base + speed bonus + streak bonus
///                    base        = battle_base_points   (default 100)
///                    speed bonus = round(battle_time_bonus_max × remaining/total)
///                    streak      = battle_streak_bonus from the 2nd
///                                  consecutive correct answer (default 25)
/// wrong / timeout →  0
/// ```
class BattleScoring {
  const BattleScoring._();

  /// The three components of one answer, for scoreboards and reveal lines.
  /// `total = base + timeBonus + streakBonus`.
  static ({int base, int timeBonus, int streakBonus}) compute({
    required bool correct,
    required int remainingSec,
    required int totalSec,
    required int streak,
    required int basePoints,
    required int timeBonusMax,
    required int streakBonus,
  }) {
    if (!correct) return (base: 0, timeBonus: 0, streakBonus: 0);

    final timeBonus = totalSec <= 0
        ? 0
        : (timeBonusMax * remainingSec / totalSec)
            .round()
            .clamp(0, timeBonusMax);
    return (
      base: basePoints,
      timeBonus: timeBonus,
      streakBonus: streak >= 1 ? streakBonus : 0,
    );
  }

  /// Total for a component triple.
  static int total(({int base, int timeBonus, int streakBonus}) parts) =>
      parts.base + parts.timeBonus + parts.streakBonus;

  /// Human-readable breakdown for the reveal line, e.g. `100 + 60 + 25`.
  static String breakdown(({int base, int timeBonus, int streakBonus}) parts) =>
      '${parts.base} + ${parts.timeBonus} + ${parts.streakBonus}';
}
