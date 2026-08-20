import 'package:flutter_test/flutter_test.dart';
import 'package:quizbaaz/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('QuizBaazApp builds without crashing', (tester) async {
    await tester.pumpWidget(const QuizBaazApp());
    await tester.pump();

    expect(find.byType(QuizBaazApp), findsOneWidget);
  });
}
