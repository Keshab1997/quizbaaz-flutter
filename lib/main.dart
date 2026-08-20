import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/battle_provider.dart';
import 'data/providers/quiz_provider.dart';
import 'data/providers/rewards_provider.dart';
import 'data/providers/user_provider.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/widgets/app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional at startup so development is never blocked.
  // Google Sign-In will report a clear error until the project is configured.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured yet: $e');
  }

  runApp(const QuizBaazApp());
}

class QuizBaazApp extends StatelessWidget {
  const QuizBaazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(
          create: (ctx) => QuizProvider(ctx.read<UserProvider>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => BattleProvider(ctx.read<UserProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => RewardsProvider()),
      ],
      child: MaterialApp(
        title: 'QuizBaaz 3D',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) => AppBackground(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
