import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/imgbb_service.dart';
import '../../../data/services/shop_service.dart';
import '../../widgets/glass_card.dart';

/// Admin screen to manage avatars
class AvatarManagerScreen extends StatefulWidget {
  final String? initialAction;
  
  const AvatarManagerScreen({super.key, this.initialAction});

  @override
  State<AvatarManagerScreen> createState() => _AvatarManagerScreenState();
}

class _AvatarManagerScreenState extends State<AvatarManagerScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialAction == 'add') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddAvatarSheet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Avatar Manager',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.neonPink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.neonPink, size: 20),
            ),
            onPressed: _showAddAvatarSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_getAvatars().length} avatars',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddAvatarSheet,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Avatar'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.neonPink),
                ),
              ],
            ),
          ),
          Expanded(child: _buildAvatarGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAvatarSheet,
        backgroundColor: AppColors.neonPink,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Avatar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'label': '🏪 All'},
      {'id': 'male', 'label': '👦 Male'},
      {'id': 'female', 'label': '👧 Female'},
      {'id': 'premium', 'label': '👑 Premium'},
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['id']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neonPurple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.neonPurple.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(cat['label']!, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppColors.neonPurple : AppColors.textSecondary)),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getAvatars() {
    switch (_selectedCategory) {
      case 'male': return AppAssets.maleAvatars;
      case 'female': return AppAssets.femaleAvatars;
      case 'premium': return AppAssets.premiumAvatars;
      default: return AppAssets.allAvatars;
    }
  }

  Widget _buildAvatarGrid() {
    final avatars = _getAvatars();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: avatars.length,
      itemBuilder: (context, index) => _buildAvatarCard(avatars[index]),
    );
  }

  Widget _buildAvatarCard(String avatar) {
    final name = _getAvatarName(avatar);
    final isPremium = AppAssets.premiumAvatars.contains(avatar);
    return GlassCard(
      borderRadius: 16,
      borderColor: isPremium ? AppColors.neonGold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(avatar, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.white.withValues(alpha: 0.05), child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 40)),
            ),
          ),
          if (isPremium)
            Positioned(top: 8, left: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.neonGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.5))),
              child: const Text('👑 PREMIUM', style: TextStyle(color: AppColors.neonGold, fontSize: 8, fontWeight: FontWeight.w900)),
            )),
          Positioned(bottom: 0, left: 0, right: 0, child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)]),
            ),
            child: Row(children: [
              Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 16),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 14), SizedBox(width: 6), Text('Edit', style: TextStyle(fontSize: 12))])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 14, color: AppColors.neonRed), SizedBox(width: 6), Text('Delete', style: TextStyle(fontSize: 12, color: AppColors.neonRed))])),
                ],
                onSelected: (value) {
                  if (value == 'delete') _showDeleteDialog(avatar);
                },
              ),
            ]),
          )),
        ],
      ),
    );
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
    if (path.contains('avatar_boy')) return 'Default Boy';
    if (path.contains('avatar_girl')) return 'Default Girl';
    return 'Avatar';
  }

  void _showAddAvatarSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => const _AddEditAvatarSheet(),
    );
  }

  void _showDeleteDialog(String avatar) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text('Delete Avatar?'),
      content: Text('Delete "${_getAvatarName(avatar)}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar deleted'))); },
          child: const Text('Delete', style: TextStyle(color: AppColors.neonRed))),
      ],
    ));
  }
}

class _AddEditAvatarSheet extends StatefulWidget {
  const _AddEditAvatarSheet();
  @override
  State<_AddEditAvatarSheet> createState() => _AddEditAvatarSheetState();
}

class _AddEditAvatarSheetState extends State<_AddEditAvatarSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'male';
  bool _isPremium = false;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 90);
      if (image != null) {
        setState(() { _selectedImage = File(image.path); _isUploading = true; });
        final url = await ImgBBService.uploadFile(_selectedImage!);
        if (url != null) {
          setState(() { _uploadedImageUrl = url; _isUploading = false; });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Avatar image uploaded!'), backgroundColor: AppColors.neonGreen));
        } else {
          setState(() => _isUploading = false);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Upload failed. Try again.'), backgroundColor: AppColors.neonRed));
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() { _nameController.dispose(); _priceController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Add New Avatar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 20),
          // Image Upload
          _buildImageUpload(),
          const SizedBox(height: 20),
          TextField(controller: _nameController, style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(labelText: 'Avatar Name', labelStyle: const TextStyle(color: AppColors.textSecondary), hintText: 'e.g., Blue Hoodie Boy',
              prefixIcon: const Icon(Icons.face_rounded, color: AppColors.neonCyan), filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))))),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _selectedCategory, style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(labelText: 'Category', labelStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.category_rounded, color: AppColors.neonCyan), filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
            dropdownColor: AppColors.surfaceElevated,
            items: const [DropdownMenuItem(value: 'male', child: Text('👦 Male')), DropdownMenuItem(value: 'female', child: Text('👧 Female')), DropdownMenuItem(value: 'premium', child: Text('👑 Premium'))],
            onChanged: (value) => setState(() => _selectedCategory = value!)),
          const SizedBox(height: 16),
          SwitchListTile(title: const Text('Premium Avatar', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: const Text('Requires purchase in shop', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            value: _isPremium, onChanged: (value) => setState(() => _isPremium = value), activeThumbColor: AppColors.neonGold),
          if (_isPremium) ...[
            const SizedBox(height: 16),
            TextField(controller: _priceController, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: 'Price (Gems)', labelStyle: const TextStyle(color: AppColors.textSecondary), hintText: '50',
                prefixIcon: const Icon(Icons.diamond_rounded, color: AppColors.neonPurple), filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))))),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveAvatar,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPink, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Add Avatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)))),
        ]),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _uploadedImageUrl != null ? AppColors.neonGreen.withValues(alpha: 0.5) : AppColors.neonPink.withValues(alpha: 0.2))),
      child: Column(children: [
        if (_selectedImage != null) ...[
          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_selectedImage!, height: 160, width: 160, fit: BoxFit.cover)),
          const SizedBox(height: 12),
          if (_isUploading) const Column(children: [CircularProgressIndicator(color: AppColors.neonPink), SizedBox(height: 8), Text('Uploading to ImageBB...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))])
          else if (_uploadedImageUrl != null) Column(children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: AppColors.neonGreen, size: 18), SizedBox(width: 6), Text('Uploaded!', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w700))]),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Change Image')),
          ])
          else TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry Upload')),
        ] else ...[
          Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.neonPink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.3))),
            child: Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppColors.neonPink.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          const Text('Upload Avatar Image', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Max 32MB • PNG, JPG recommended', style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.upload_rounded), label: const Text('Choose from Gallery'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
        ],
        if (_uploadedImageUrl != null) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [const Icon(Icons.link_rounded, color: AppColors.neonPink, size: 14), const SizedBox(width: 6),
              Expanded(child: Text(_uploadedImageUrl!, style: const TextStyle(color: AppColors.neonPink, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis))])),
        ],
      ]),
    );
  }

  void _saveAvatar() async {
    final avatarData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'New Avatar',
      'category': _selectedCategory,
      'image_url': _uploadedImageUrl ?? '',
      'is_premium': _isPremium,
      'price': _isPremium ? (int.tryParse(_priceController.text) ?? 50) : 0,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    final success = await ShopService.saveAvatar(avatarData);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Avatar added!' : '❌ Failed to save. Try again.'),
          backgroundColor: success ? AppColors.neonPink : AppColors.neonRed,
        ),
      );
    }
  }
}
