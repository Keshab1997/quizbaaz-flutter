import 'package:flutter_test/flutter_test.dart';
import 'package:quizbaaz/data/models/battle_scoring.dart';

void main() {
  const base = 10;
  const speed = 5;
  const streakPer = 2;

  group('BattleScoring — new formula (10 + 5 + 2×streak)', () {
    test('wrong answer pays nothing', () {
      final parts = BattleScoring.compute(
        correct: false,
        answeredBeforeOpponent: true,
        streak: 3,
        basePoints: base,
        speedBonus: speed,
        streakBonusPerStreak: streakPer,
      );
      expect(BattleScoring.total(parts), 0);
      expect(parts.base, 0);
      expect(parts.speedBonus, 0);
      expect(parts.streakBonus, 0);
    });

    test('correct, answered first, no streak → 10 + 5 = 15', () {
      final parts = BattleScoring.compute(
        correct: true,
        answeredBeforeOpponent: true,
        streak: 0,
        basePoints: base,
        speedBonus: speed,
        streakBonusPerStreak: streakPer,
      );
      expect(parts.base, 10);
      expect(parts.speedBonus, 5);
      expect(parts.streakBonus, 0);
      expect(BattleScoring.total(parts), 15);
    });

    test('correct, answered after opponent, no streak → 10 only', () {
      final parts = BattleScoring.compute(
        correct: true,
        answeredBeforeOpponent: false,
        streak: 0,
        basePoints: base,
        speedBonus: speed,
        streakBonusPerStreak: streakPer,
      );
      expect(parts.base, 10);
      expect(parts.speedBonus, 0);
      expect(BattleScoring.total(parts), 10);
    });

    test('streak=1 → +2×1=2 streak bonus', () {
      final parts = BattleScoring.compute(
        correct: true,
        answeredBeforeOpponent: false,
        streak: 1,
        basePoints: base,
        speedBonus: speed,
        streakBonusPerStreak: streakPer,
      );
      expect(parts.streakBonus, 2);
      expect(BattleScoring.total(parts), 12);
    });

    test('streak=3 → +2×3=6 streak bonus, first → 10+5+6=21', () {
      final parts = BattleScoring.compute(
        correct: true,
        answeredBeforeOpponent: true,
        streak: 3,
        basePoints: base,
        speedBonus: speed,
        streakBonusPerStreak: streakPer,
      );
      expect(parts.base, 10);
      expect(parts.speedBonus, 5);
      expect(parts.streakBonus, 6);
      expect(BattleScoring.total(parts), 21);
    });

    test('breakdown string format', () {
      final parts = BattleScoring.compute(
        correct: true,
        answeredBeforeOpponent: true,
        streak: 2,
        basePoints: base,
        speedBonus: speed,
        streakBonusPerStreak: streakPer,
      );
      expect(BattleScoring.breakdown(parts), '10 + 5 + 4');
    });
  });
}
