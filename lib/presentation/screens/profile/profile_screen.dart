import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final user = userProvider.user;

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
                        child: Image.asset(
                          user.avatarPath,
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

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.orangeAccent, size: 28),
                        const SizedBox(height: 6),
                        Text('${user.dailyStreak} Days',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const Text('Current Streak',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: AppColors.neonGold, size: 28),
                        const SizedBox(height: 6),
                        Text('${user.coins}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const Text('Coins Earned',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBadge('Top 1 Winner', Icons.military_tech,
                          AppColors.neonGold),
                      _buildBadge(
                          '7 Day Streak', Icons.whatshot, Colors.orangeAccent),
                      _buildBadge(
                          'Speed Demon', Icons.bolt, AppColors.neonCyan),
                    ],
                  ),
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
          ],
        ),
      ),
    );
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