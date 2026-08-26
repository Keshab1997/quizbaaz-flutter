import 'package:flutter_test/flutter_test.dart';
import 'package:quizbaaz/data/models/battle_scoring.dart';

void main() {
  const base = 100;
  const speed = 100;
  const streak = 25;

  group('BattleScoring', () {
    test('wrong answer pays nothing', () {
      final parts = BattleScoring.compute(
        correct: false,
        remainingSec: 10,
        totalSec: 15,
        streak: 3,
        basePoints: base,
        timeBonusMax: speed,
        streakBonus: streak,
      );
      expect(BattleScoring.total(parts), 0);
      expect(parts.base, 0);
    });

    test('full speed + base, no streak', () {
      final parts = BattleScoring.compute(
        correct: true,
        remainingSec: 15,
        totalSec: 15,
        streak: 0,
        basePoints: base,
        timeBonusMax: speed,
        streakBonus: streak,
      );
      expect(BattleScoring.total(parts), 200);
    });

    test('half time remaining gives half the speed bonus', () {
      final parts = BattleScoring.compute(
        correct: true,
        remainingSec: 8,
        totalSec: 15,
        streak: 0,
        basePoints: base,
        timeBonusMax: speed,
        streakBonus: streak,
      );
      // 100 * 8 / 15 = 53.33 → 53
      expect(parts.timeBonus, 53);
      expect(BattleScoring.total(parts), 153);
    });

    test('2nd consecutive correct earns the streak bonus', () {
      final parts = BattleScoring.compute(
        correct: true,
        remainingSec: 4,
        totalSec: 15,
        streak: 1,
        basePoints: base,
        timeBonusMax: speed,
        streakBonus: streak,
      );
      // 100 * 4 / 15 = 26.67 → 27; + streak 25 → 152
      expect(parts.timeBonus, 27);
      expect(parts.streakBonus, 25);
      expect(BattleScoring.total(parts), 152);
    });

    test('timeout answer pays nothing even after a streak', () {
      final parts = BattleScoring.compute(
        correct: false,
        remainingSec: 0,
        totalSec: 15,
        streak: 4,
        basePoints: base,
        timeBonusMax: speed,
        streakBonus: streak,
      );
      expect(BattleScoring.total(parts), 0);
    });

    test('speed bonus never exceeds the cap', () {
      final parts = BattleScoring.compute(
        correct: true,
        remainingSec: 60,
        totalSec: 15,
        streak: 0,
        basePoints: base,
        timeBonusMax: speed,
        streakBonus: streak,
      );
      expect(parts.timeBonus, 100);
    });

    test('breakdown line reads base + speed + streak', () {
      final parts = BattleScoring.compute(
        correct: true,
        remainingSec: 6,
        totalSec: 15,
        streak: 2,
        basePoints: base,
        timeBonusMax: speed,
        streakBonus: streak,
      );
      expect(BattleScoring.breakdown(parts), '100 + 40 + 25');
      expect(BattleScoring.total(parts), 165);
    });

    test('custom config is honoured (admin-tuned battle)', () {
      final parts = BattleScoring.compute(
        correct: true,
        remainingSec: 10,
        totalSec: 20,
        streak: 0,
        basePoints: 50,
        timeBonusMax: 40,
        streakBonus: 10,
      );
      // 40 * 10 / 20 = 20
      expect(BattleScoring.total(parts), 70);
    });
  });
}
