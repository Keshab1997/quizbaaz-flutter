import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quizbaaz/data/models/user_stats.dart';
import 'package:quizbaaz/data/services/hive_service.dart';
import 'package:quizbaaz/main.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('quizbaaz_test_');
    Hive.init(tempDir.path);
    await HiveService.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('QuizBaazApp builds without crashing', (tester) async {
    await tester.pumpWidget(const QuizBaazApp());
    await tester.pump();

    expect(find.byType(QuizBaazApp), findsOneWidget);
  });

  test('a fresh install starts with zeroed stats (no fake data)', () {
    final stats = HiveService.loadStats();
    expect(stats.totalAnswered, 0);
    expect(stats.totalCorrect, 0);
    expect(stats.hasData, isFalse);
    expect(stats.accuracyLabel, '--');
  });

  test('stats survive a Hive round-trip', () async {
    final stats = UserStats.empty()
      ..recordQuiz(
        answered: 10,
        correct: 8,
        timeSeconds: 60,
        isDaily: true,
        dailyScore: 120,
      );
    await HiveService.saveStats(stats);

    final restored = HiveService.loadStats();
    expect(restored.totalAnswered, 10);
    expect(restored.totalCorrect, 8);
    expect(restored.accuracyRounded, 80);
    expect(restored.bestDailyScore, 120);
  });

  test('offline writes are queued and can be drained', () async {
    await HiveService.clearPending();
    await HiveService.enqueuePending('save_user', {'user_id': 'u1'});
    expect(HiveService.pendingCount, 1);

    final ops = HiveService.pendingOps();
    expect(ops.first.value['type'], 'save_user');

    await HiveService.removePending(ops.first.key);
    expect(HiveService.pendingCount, 0);
  });
}
