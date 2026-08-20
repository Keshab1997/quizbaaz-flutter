import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/battle_provider.dart';
import 'data/providers/quiz_provider.dart';
import 'data/providers/rewards_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/services/firebase_options.dart';
import 'data/services/hive_service.dart';
import 'data/services/sync_service.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/widgets/app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Hive is the source of truth — it must be ready before anything reads.
  await Hive.initFlutter();
  await HiveService.initialize();

  // 2) Firebase is optional: the whole app works offline without it.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not configured yet: $e');
  }

  // 3) Replay anything queued while the app was offline, then refresh config.
  unawaitedSync();

  runApp(const QuizBaazApp());
}

/// Fire-and-forget startup sync (never blocks the first frame).
void unawaitedSync() {
  Future(() async {
    if (!SyncService.isOnline) return;
    await SyncService.drainPending();
    await SyncService.pullConfig();
  });
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
