import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/user_stats.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final user = userProvider.user;
    final stats = userProvider.stats;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.neonCyan),
            onPressed: () => _showEditProfileSheet(context, userProvider, user),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Avatar & Info
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showGenderPicker(context, userProvider),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.neonCyan, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(45),
                        child: user.hasGoogleAvatar
                            ? Image.network(
                                user.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  user.effectiveAvatar,
                                  fit: BoxFit.cover,
                                ),
                                loadingBuilder: (ctx, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)),
                              )
                            : Image.asset(
                                user.effectiveAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person,
                                        size: 50, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showEditProfileSheet(context, userProvider, user),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_rounded,
                            size: 16, color: AppColors.neonCyan),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.neonCyan),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (user.gender == UserGender.male
                                  ? AppColors.neonCyan
                                  : AppColors.neonPink)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user.gender == UserGender.male ? 'Male' : 'Female',
                          style: TextStyle(
                            fontSize: 11,
                            color: user.gender == UserGender.male
                                ? AppColors.neonCyan
                                : AppColors.neonPink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid — every number comes from Hive-backed UserStats
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.local_fire_department,
                    color: Colors.orangeAccent,
                    value: '${user.dailyStreak}',
                    label: 'Day Streak',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.monetization_on_rounded,
                    color: AppColors.neonGold,
                    value: '${user.coins}',
                    label: 'Coins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.track_changes_rounded,
                    color: AppColors.neonCyan,
                    value: stats.accuracyLabel,
                    label: 'Accuracy',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.quiz_rounded,
                    color: AppColors.neonPurple,
                    value: '${stats.totalQuizzes}',
                    label: 'Quizzes Played',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PERFORMANCE',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.check_circle_rounded, 'Correct answers',
                      '${stats.totalCorrect} / ${stats.totalAnswered}'),
                  const Divider(color: Colors.white12),
                  _buildDetailRow(Icons.emoji_events_rounded, 'Best daily score',
                      stats.bestDailyScore > 0
                          ? '${stats.bestDailyScore} pts'
                          : '--'),
                  const Divider(color: Colors.white12),
                  _buildDetailRow(Icons.bolt_rounded, 'Battles won',
                      '${stats.battlesWon} / ${stats.battlesPlayed}'),
                  const Divider(color: Colors.white12),
                  _buildDetailRow(Icons.timer_rounded, 'Avg. time / question',
                      stats.hasData
                          ? '${stats.averageSecondsPerQuestion.toStringAsFixed(1)}s'
                          : '--'),
                  const Divider(color: Colors.white12),
                  _buildDetailRow(Icons.whatshot_rounded, 'Longest streak',
                      '${stats.longestStreak} days'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Details Card
            GlassCard(
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PROFILE DETAILS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.person_rounded, 'Username',
                      '@${user.username}'),
                  const Divider(color: Colors.white12),
                  _buildDetailRow(
                      Icons.badge_rounded, 'Full Name', user.fullName),
                  const Divider(color: Colors.white12),
                  _buildDetailRow(
                    Icons.wc_rounded,
                    'Gender',
                    user.gender == UserGender.male ? 'Male' : 'Female',
                    trailing: GestureDetector(
                      onTap: () => _showGenderPicker(context, userProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.neonCyan.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Change',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  _buildDetailRow(Icons.email_rounded, 'Email',
                      auth.firebaseUser?.email ?? 'Not connected'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Badges
            GlassCard(
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BADGES & ACHIEVEMENTS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  Builder(builder: (context) {
                    final earned = _earnedBadges(stats, user.dailyStreak);
                    if (earned.isEmpty) {
                      return const Text(
                        'No badges yet — play quizzes to unlock them.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      );
                    }
                    return Wrap(
                      spacing: 18,
                      runSpacing: 14,
                      children: earned
                          .map((b) => _buildBadge(b.title, b.icon, b.color))
                          .toList(),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mode switcher
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.white.withValues(alpha: 0.05),
              leading:
                  const Icon(Icons.swap_horiz, color: AppColors.neonCyan),
              title: Text(user.isGuest
                  ? 'Currently: Guest Mode'
                  : 'Currently: Registered User'),
              subtitle: Text(user.isGuest
                  ? 'Tap to switch to Full User'
                  : 'Tap to test Guest Mode'),
              trailing: Switch(
                value: !user.isGuest,
                activeThumbColor: AppColors.neonCyan,
                onChanged: (val) {
                  userProvider.setGuestMode(!val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Google Account
            GlassCard(
              borderRadius: 16,
              child: Row(
                children: [
                  const Icon(Icons.g_mobiledata,
                      size: 34, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isSignedIn
                              ? (auth.firebaseUser?.displayName ??
                                  'Google Account')
                              : 'Google Account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.isSignedIn
                              ? auth.firebaseUser?.email ?? 'Connected'
                              : 'Sign in to save your progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: auth.isSignedIn
                                ? AppColors.neonGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (auth.isSignedIn)
                    TextButton(
                      onPressed: () => auth.signOut(),
                      child: const Text('Sign Out',
                          style: TextStyle(
                              color: AppColors.neonRed,
                              fontWeight: FontWeight.bold)),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                           auth.isBusy ? null : () => _handleGoogleSignIn(context),
                      child: Text(
                        auth.isBusy ? 'Wait...' : 'Sign In',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),

            // Settings Section
            _buildSectionTitle(Icons.settings_rounded, 'Settings'),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildSettingRow(userProvider, Icons.notifications_rounded,
                      'Notifications', UserProvider.settingNotifications),
                  const Divider(color: Colors.white12),
                  _buildSettingRow(userProvider, Icons.music_note_rounded,
                      'Sound Effects', UserProvider.settingSound),
                  const Divider(color: Colors.white12),
                  _buildSettingRow(userProvider, Icons.volume_up_rounded,
                      'Vibration', UserProvider.settingVibration,
                      defaultValue: false),
                  const Divider(color: Colors.white12),
                  _buildSettingRow(userProvider, Icons.dark_mode_rounded,
                      'Dark Mode', UserProvider.settingDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Section
            _buildSectionTitle(Icons.info_outline_rounded, 'About'),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildAppInfoRow(Icons.star_rounded, 'Rate the App', () {}),
                  const Divider(color: Colors.white12),
                  _buildAppInfoRow(Icons.share_rounded, 'Share with Friends', () {}),
                  const Divider(color: Colors.white12),
                  _buildAppInfoRow(Icons.policy_rounded, 'Privacy Policy', () {}),
                  const Divider(color: Colors.white12),
                  _buildAppInfoRow(Icons.description_rounded, 'Terms & Conditions', () {}),
                  const Divider(color: Colors.white12),
                  _buildAppInfoRow(Icons.info_rounded, 'Version 1.0.0', null),
                  if (auth.isSignedIn) ...[
                    const Divider(color: Colors.white12),
                    _buildAppInfoRow(Icons.logout_rounded, 'Sign Out',
                        () => _confirmSignOut(context, auth),
                        color: AppColors.neonRed),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out? Your local data will be kept.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.neonRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.signOut();
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neonCyan),
          const SizedBox(width: 10),          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Badges are derived from real stats — nothing is shown "for free".
  List<_Badge> _earnedBadges(UserStats stats, int streak) {
    final badges = <_Badge>[];
    if (stats.bestDailyScore > 0) {
      badges.add(const _Badge(
          'First Score', Icons.flag_rounded, AppColors.neonCyan));
    }
    if (streak >= 7 || stats.longestStreak >= 7) {
      badges.add(const _Badge(
          '7 Day Streak', Icons.whatshot, Colors.orangeAccent));
    }
    if (stats.totalQuizzes >= 10) {
      badges.add(const _Badge(
          '10 Quizzes', Icons.school_rounded, AppColors.neonPurple));
    }
    if (stats.accuracyPercent >= 80 && stats.totalAnswered >= 20) {
      badges.add(const _Badge(
          'Sharp Shooter', Icons.military_tech, AppColors.neonGold));
    }
    if (stats.hasData && stats.averageSecondsPerQuestion > 0 &&
        stats.averageSecondsPerQuestion <= 6) {
      badges.add(const _Badge('Speed Demon', Icons.bolt, AppColors.neonCyan));
    }
    if (stats.battlesWon >= 5) {
      badges.add(const _Badge(
          'Battle Master', Icons.sports_mma_rounded, AppColors.neonPink));
    }
    return badges;
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }

  void _showEditProfileSheet(
      BuildContext context, UserProvider userProvider, UserModel user) {
    final nameController =
        TextEditingController(text: user.fullName);
    final usernameController =
        TextEditingController(text: user.username);
    UserGender selectedGender = user.gender;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Profile',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonCyan),
                      ),),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonCyan),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('Gender',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderOption(
                          'Male',
                          UserGender.male,
                          selectedGender == UserGender.male,
                          () => setState(() => selectedGender = UserGender.male),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderOption(
                          'Female',
                          UserGender.female,
                          selectedGender == UserGender.female,
                          () => setState(() => selectedGender = UserGender.female),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        userProvider.saveProfile(
                          username: usernameController.text.trim().isEmpty
                              ? user.username
                              : usernameController.text.trim(),
                          fullName: nameController.text.trim().isEmpty
                              ? user.fullName
                              : nameController.text.trim(),
                          gender: selectedGender,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('✅ Profile updated successfully!')),
                        );
                      },
                      child: const Text('SAVE PROFILE',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGenderOption(
    String label,
    UserGender gender,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (gender == UserGender.male
                      ? AppColors.neonCyan
                      : AppColors.neonPink)
                  .withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (gender == UserGender.male
                        ? AppColors.neonCyan
                        : AppColors.neonPink)
                    .withValues(alpha: 0.8)
                : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              gender == UserGender.male
                  ? Icons.male_rounded
                  : Icons.female_rounded,
              color: isSelected
                  ? (gender == UserGender.male
                          ? AppColors.neonCyan
                          : AppColors.neonPink)
                  : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (gender == UserGender.male
                            ? AppColors.neonCyan
                            : AppColors.neonPink)
                    : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Gender',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption(
                      'Male',
                      UserGender.male,
                      false,
                      () {
                        userProvider.updateGender(UserGender.male);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption(
                      'Female',
                      UserGender.female,
                      false,
                      () {
                        userProvider.updateGender(UserGender.female);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Reads and writes the toggle straight through Hive — no dead switches.
  Widget _buildSettingRow(
    UserProvider userProvider,
    IconData icon,
    String label,
    String settingKey, {
    bool defaultValue = true,
  }) {
    final isOn = userProvider.setting(settingKey, defaultValue: defaultValue);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.neonCyan),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
        Switch(
          value: isOn,
          onChanged: (val) => userProvider.setSetting(settingKey, val),
          activeTrackColor: AppColors.neonCyan.withValues(alpha: 0.5),
          activeThumbColor: AppColors.neonCyan,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neonCyan),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildGameStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoRow(IconData icon, String label, VoidCallback? onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.neonCyan),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color ?? Colors.white)),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

Future<void> _handleGoogleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final signedIn = await auth.signInWithGoogle();
      if (!signedIn) return;

      final user = auth.firebaseUser;
      if (user == null) return;

      userProvider.linkGoogleAccount(
        user.displayName ?? 'QuizBaaz Player',
        user.email ?? 'player@quizbaaz.app',
        photoURL: user.photoURL?.toString(),
      );

      messenger.showSnackBar(
        const SnackBar(content: Text('🎉 Signed in with Google!')),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade800),
      );
    }
  }
}

/// A badge the player has actually earned.
class _Badge {
  final String title;
  final IconData icon;
  final Color color;

  const _Badge(this.title, this.icon, this.color);
}
