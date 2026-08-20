import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/battle_provider.dart';
import 'data/providers/quiz_provider.dart';
import 'data/providers/rewards_provider.dart';
import 'data/providers/user_provider.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuizBaazApp());
}

class QuizBaazApp extends StatelessWidget {
  const QuizBaazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (ctx) => QuizProvider(ctx.read<UserProvider>())),
        ChangeNotifierProvider(create: (ctx) => BattleProvider(ctx.read<UserProvider>())),
        ChangeNotifierProvider(create: (_) => RewardsProvider()),
      ],
      child: MaterialApp(
        title: 'QuizBaaz 3D',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}
