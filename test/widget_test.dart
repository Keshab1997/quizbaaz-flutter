import 'package:flutter_test/flutter_test.dart';
import 'package:quizcraft/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('QuizCraftApp builds without crashing', (tester) async {
    await tester.pumpWidget(const QuizCraftApp());
    await tester.pump();

    expect(find.byType(QuizCraftApp), findsOneWidget);
  });
}
