import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/services/shop_service.dart';
import '../../widgets/glass_card.dart';

/// Screen where users can browse and select their profile avatar.
/// Shows all available avatars: default, free, and premium (from shop).
class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  String _selectedCategory = 'male';
  String? _selectedAvatar;
  List<Map<String, dynamic>> _cloudAvatars = [];
  bool _isLoadingCloud = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _selectedAvatar = userProvider.user.avatarPath;
    _loadCloudAvatars();
  }

  Future<void> _loadCloudAvatars() async {
    setState(() => _isLoadingCloud = true);
    try {
      final avatars = await ShopService.getAvatars();
      if (mounted) {
        setState(() {
          _cloudAvatars = avatars;
          _isLoadingCloud = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCloud = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Avatar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _selectedAvatar != null
                ? () => _saveAvatar(context, userProvider)
                : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _selectedAvatar != null
                    ? AppColors.neonCyan
                    : AppColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Current Avatar Preview
          _buildCurrentAvatarPreview(user.avatarPath),

          // Category Tabs
          _buildCategoryTabs(),

          // Avatar Grid
          Expanded(
            child: _buildAvatarGrid(userProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentAvatarPreview(String currentAvatar) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GlassCard(
        borderRadius: 20,
        borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Current Avatar (larger, rounded rectangle)
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonPurple.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      currentAvatar,
                      fit: BoxFit.contain,
                      width: 84,
                      height: 84,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Avatar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAvatarName(currentAvatar),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap an avatar below to change',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Preview selected
              if (_selectedAvatar != null && _selectedAvatar != currentAvatar)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.neonGold.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.neonGold, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'New',
                        style: TextStyle(
                          color: AppColors.neonGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'id': 'male', 'label': '👦 Male', 'icon': Icons.male_rounded},
      {'id': 'female', 'label': '👧 Female', 'icon': Icons.female_rounded},
      {'id': 'premium', 'label': '👑 Premium', 'icon': Icons.workspace_premium_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.neonPurple.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.neonPurple.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? AppColors.neonPurple : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          color: isSelected ? AppColors.neonPurple : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatarGrid(UserProvider userProvider) {
    List<String> avatars;
    List<String> ownedItems = [];

    switch (_selectedCategory) {
      case 'male':
        avatars = AppAssets.maleAvatars;
        break;
      case 'female':
        avatars = AppAssets.femaleAvatars;
        break;
      case 'premium':
        avatars = AppAssets.premiumAvatars;
        ownedItems = _getOwnedPremiumAvatars(userProvider);
        break;
      default:
        avatars = AppAssets.maleAvatars;
    }

    // Filter cloud avatars by category
    final cloudAvatars = _selectedCategory == 'all'
        ? _cloudAvatars
        : _cloudAvatars.where((a) => a['category'] == _selectedCategory).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Local Avatars
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final avatar = avatars[index];
                final isSelected = _selectedAvatar == avatar;
                final isPremium = _selectedCategory == 'premium';
                final isOwned = !isPremium || ownedItems.contains(avatar);

                return _buildAvatarCard(
                  avatar: avatar,
                  isSelected: isSelected,
                  isPremium: isPremium,
                  isOwned: isOwned,
                  onTap: () {
                    if (isPremium && !isOwned) {
                      _showPurchaseDialog(context, avatar);
                    } else {
                      setState(() => _selectedAvatar = avatar);
                    }
                  },
                );
              },
              childCount: avatars.length,
            ),
          ),
        ),

        // Cloud Avatars Section
        if (cloudAvatars.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_rounded, color: AppColors.neonCyan, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'CLOUD AVATARS',
                          style: TextStyle(
                            color: AppColors.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cloudAvatar = cloudAvatars[index];
                  final imageUrl = cloudAvatar['image_url'] as String? ?? '';
                  final isSelected = _selectedAvatar == imageUrl;
                  final isPremium = cloudAvatar['is_premium'] ?? false;

                  return _buildCloudAvatarCard(
                    cloudAvatar: cloudAvatar,
                    imageUrl: imageUrl,
                    isSelected: isSelected,
                    isPremium: isPremium,
                    onTap: () {
                      if (isPremium) {
                        // Check if owned
                        _showPurchaseDialog(context, imageUrl);
                      } else {
                        setState(() => _selectedAvatar = imageUrl);
                      }
                    },
                  );
                },
                childCount: cloudAvatars.length,
              ),
            ),
          ),
        ],

        // Loading indicator
        if (_isLoadingCloud)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarCard({
    required String avatar,
    required bool isSelected,
    required bool isPremium,
    required bool isOwned,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.neonCyan.withValues(alpha: 0.8)
                : isPremium && !isOwned
                    ? AppColors.neonGold.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Avatar Image (full image, no circle crop)
              Container(
                color: Colors.white.withValues(alpha: 0.03),
                child: Image.asset(
                  avatar,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withValues(alpha: 0.05),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.textMuted,
                      size: 50,
                    ),
                  ),
                ),
              ),

              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),

              // Premium lock overlay
              if (isPremium && !isOwned)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.neonGold.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.neonGold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: AppColors.neonGold,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neonGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SHOP',
                            style: TextStyle(
                              color: AppColors.neonGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Premium badge
              if (isPremium && isOwned)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.neonGold.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified,
                            color: AppColors.neonGold, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'OWNED',
                          style: TextStyle(
                            color: AppColors.neonGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudAvatarCard({
    required Map<String, dynamic> cloudAvatar,
    required String imageUrl,
    required bool isSelected,
    required bool isPremium,
    required VoidCallback onTap,
  }) {
    final name = cloudAvatar['name'] as String? ?? 'Avatar';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.neonCyan.withValues(alpha: 0.8)
                : isPremium
                    ? AppColors.neonGold.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cloud Image
              imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(Icons.cloud_rounded, color: AppColors.textMuted, size: 40),
                    ),

              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  ),
                ),

              // Cloud badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_rounded, color: AppColors.neonCyan, size: 10),
                      SizedBox(width: 3),
                      Text(
                        'CLOUD',
                        style: TextStyle(color: AppColors.neonCyan, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),

              // Name
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getOwnedPremiumAvatars(UserProvider userProvider) {
    final owned = <String>[];
    if (userProvider.hasItem('vip_avatar')) owned.add(AppAssets.vipAvatar);
    if (userProvider.hasItem('golden_avatar')) owned.add(AppAssets.goldenKnightAvatar);
    if (userProvider.hasItem('neon_avatar')) owned.add(AppAssets.neonCyberAvatar);
    if (userProvider.hasItem('royal_avatar')) owned.add(AppAssets.royalCrownAvatar);
    return owned;
  }

  String _getAvatarName(String path) {
    if (path.contains('male_avatar_1')) return 'Blue Hoodie Boy';
    if (path.contains('male_avatar_2')) return 'Red Gamer Boy';
    if (path.contains('male_avatar_3')) return 'Smart Scholar';
    if (path.contains('male_avatar_4')) return 'Cool DJ Boy';
    if (path.contains('female_avatar_1')) return 'Pink Ponytail Girl';
    if (path.contains('female_avatar_2')) return 'Traditional Girl';
    if (path.contains('female_avatar_3')) return 'Smart Girl';
    if (path.contains('female_avatar_4')) return 'Modern Girl';
    if (path.contains('vip_avatar')) return 'VIP Golden Avatar';
    if (path.contains('golden_knight')) return 'Golden Knight';
    if (path.contains('neon_cyber')) return 'Neon Cyber';
    if (path.contains('royal_crown')) return 'Royal Crown';
    if (path.contains('avatar_boy')) return 'Default Boy';
    if (path.contains('avatar_girl')) return 'Default Girl';
    return 'Custom Avatar';
  }

  void _saveAvatar(BuildContext context, UserProvider userProvider) {
    if (_selectedAvatar == null) return;

    // Determine gender from avatar
    final isFemale = _selectedAvatar!.contains('female') ||
        _selectedAvatar!.contains('girl');

    // Update avatar path directly
    userProvider.updateAvatar(_selectedAvatar!);

    // Update gender if needed
    if (isFemale && userProvider.user.gender != UserGender.female) {
      userProvider.updateGender(UserGender.female);
    } else if (!isFemale && userProvider.user.gender != UserGender.male) {
      userProvider.updateGender(UserGender.male);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Avatar updated successfully!'),
        backgroundColor: AppColors.neonGreen,
      ),
    );

    Navigator.pop(context);
  }

  void _showPurchaseDialog(BuildContext context, String avatar) {
    String itemName;

    if (avatar == AppAssets.vipAvatar) {
      itemName = 'VIP Golden Avatar';
    } else if (avatar == AppAssets.goldenKnightAvatar) {
      itemName = 'Golden Knight Avatar';
    } else if (avatar == AppAssets.neonCyberAvatar) {
      itemName = 'Neon Cyber Avatar';
    } else {
      itemName = 'Royal Crown Avatar';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.neonGold),
            const SizedBox(width: 8),
            Text(itemName),
          ],
        ),
        content: const Text(
          'This is a premium avatar. Visit the Shop to purchase it first!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGold,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to profile
              // Navigate to shop (you can add this navigation)
            },
            child: const Text('Go to Shop', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
