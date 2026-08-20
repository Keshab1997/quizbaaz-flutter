import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/services/sync_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

/// Admin control panel.
///
/// Every number here is a real Firestore aggregate — there are no mock
/// metrics. The screen is only reachable for accounts flagged as admin.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final QuizRepository _repository = QuizRepository();

  Map<String, int> _metrics = const {};
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _loading = true);
    final metrics = await FirestoreService.adminMetrics();
    if (!mounted) return;
    setState(() {
      _metrics = metrics;
      _loading = false;
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshQuestionBank() async {
    setState(() => _busy = true);
    await _repository.invalidateQuestionCache();
    final questions = await _repository.getDailyQuizQuestions();
    final chapters = await _repository.getCategoriesAndChapters();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('Question cache rebuilt — ${questions.length} daily questions, '
        '${chapters.length} categories.');
  }

  Future<void> _publishChampions() async {
    setState(() => _busy = true);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final scores = await FirestoreService.getLeaderboard(yesterday, limit: 10);

    if (scores.isEmpty) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('No scores recorded for ${FirestoreService.dateKey(yesterday)}.');
      return;
    }

    final winners = scores
        .map((row) => {
              'rank': row['rank'],
              'user_id': row['user_id'],
              'name': row['name'] ?? row['username'],
              'username': row['username'],
              'avatar_path': row['avatar_path'],
              'score': row['score'],
              'time_seconds': row['time_seconds'],
              'gift_name': '',
              'gift_icon': '',
              'bonus_coins': 0,
              'badge_title': row['rank'] == 1 ? 'Grand Champion' : '',
            })
        .toList();

    final ok = await FirestoreService.publishChampions(yesterday, winners);
    if (ok) await SyncService.pullChampions(date: yesterday);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(ok
        ? 'Published ${winners.length} champions for '
            '${FirestoreService.dateKey(yesterday)}.'
        : 'Publishing failed — check your connection.');
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    final userProvider = context.read<UserProvider>();
    final replayed = await SyncService.drainPending();
    await userProvider.refreshRankings(force: true);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('Sync complete — $replayed queued write(s) replayed.');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    // Hard guard: non-admins never see the panel contents.
    if (!userProvider.isAdmin) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin'),
          backgroundColor: const Color(0xFF0F172A),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 48, color: AppColors.textMuted),
                SizedBox(height: 14),
                Text(
                  'Admin access required',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 6),
                Text(
                  'This account is not on the admin list.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Admin Web Control Panel',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadMetrics,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload metrics',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.neonCyan,
        onRefresh: _loadMetrics,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('SYSTEM OVERVIEW',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.1)),
            const SizedBox(height: 10),
            if (!SyncService.isOnline)
              _buildNotice(
                Icons.cloud_off_rounded,
                'Firebase is not connected — live metrics are unavailable.',
              )
            else if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.neonCyan),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      '${_metrics['total_users'] ?? 0}',
                      'Registered Users',
                      AppColors.neonCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      '${_metrics['players_today'] ?? 0}',
                      'Players Today',
                      AppColors.neonGold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    '${_metrics['guest_users'] ?? 0}',
                    'Guest Accounts',
                    AppColors.neonPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    '${HiveService.pendingCount}',
                    'Queued Local Writes',
                    AppColors.neonPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNotice(
              Icons.sync_rounded,
              HiveService.lastSyncAt == null
                  ? 'Never synced with Firestore yet.'
                  : 'Last sync: ${_formatTime(HiveService.lastSyncAt!)}',
            ),
            const SizedBox(height: 20),

            // Question bank
            GlassCard(
              borderRadius: 20,
              borderColor: AppColors.neonPurple.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.upload_file, color: AppColors.neonPurple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Question Bank Cache',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Clears the Hive cache and reloads every question bank '
                      'so newly published questions go live.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  NeonButton(
                    text: 'Rebuild Question Cache',
                    height: 42,
                    gradient: AppColors.primaryGradient,
                    onPressed: () {
                      if (!_busy) _refreshQuestionBank();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Champions
            GlassCard(
              borderRadius: 20,
              borderColor: AppColors.neonGold.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, color: AppColors.neonGold),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text("Declare Yesterday's Champions",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Snapshots yesterday\'s leaderboard into the champions '
                      'collection that every device reads.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  NeonButton(
                    text: 'Publish Champions',
                    height: 42,
                    onPressed: () {
                      if (!_busy) _publishChampions();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sync
            GlassCard(
              borderRadius: 20,
              borderColor: AppColors.neonCyan.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_sync_rounded, color: AppColors.neonCyan),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Force Sync',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Replays every queued offline write and refreshes the '
                      'ranking caches.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  NeonButton(
                    text: 'Sync Now',
                    height: 42,
                    onPressed: () {
                      if (!_busy) _syncNow();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String value, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildNotice(IconData icon, String message) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '${time.day}/${time.month} $h:$m';
  }
}
