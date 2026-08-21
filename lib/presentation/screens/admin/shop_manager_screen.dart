import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/shop_item.dart';
import '../../../data/services/imgbb_service.dart';
import '../../widgets/glass_card.dart';

/// Admin screen to manage shop items
class ShopManagerScreen extends StatefulWidget {
  final String? initialAction;
  
  const ShopManagerScreen({super.key, this.initialAction});

  @override
  State<ShopManagerScreen> createState() => _ShopManagerScreenState();
}

class _ShopManagerScreenState extends State<ShopManagerScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialAction == 'add') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddItemSheet();
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
          'Shop Manager',
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
                color: AppColors.neonGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.neonGreen, size: 20),
            ),
            onPressed: _showAddItemSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),
          const SizedBox(height: 12),

          // Items Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_getFilteredItems().length} items',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddItemSheet,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Item'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.neonGreen,
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: _buildItemsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemSheet,
        backgroundColor: AppColors.neonGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['all', ...ShopCatalog.categories];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final label = cat == 'all'
              ? '🏪 All'
              : ShopCatalog.categoryName(cat).split(' ').skip(1).join(' ');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.neonGold.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.neonGold.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.neonGold : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<ShopItem> _getFilteredItems() {
    if (_selectedCategory == 'all') {
      return ShopCatalog.items;
    }
    return ShopCatalog.itemsByCategory(_selectedCategory);
  }

  Widget _buildItemsList() {
    final items = _getFilteredItems();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(ShopItem item) {
    final isCoins = item.costsCoins;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 14,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppColors.neonCyan, size: 20),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCoins
                      ? AppColors.neonGold.withValues(alpha: 0.15)
                      : AppColors.neonPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCoins ? Icons.monetization_on_rounded : Icons.diamond_rounded,
                      color: isCoins ? AppColors.neonGold : AppColors.neonPurple,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.cost}',
                      style: TextStyle(
                        color: isCoins ? AppColors.neonGold : AppColors.neonPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 16, color: AppColors.neonRed),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.neonRed)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditItemSheet(item);
                  } else if (value == 'delete') {
                    _showDeleteDialog(item);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddEditItemSheet(),
    );
  }

  void _showEditItemSheet(ShopItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditItemSheet(item: item),
    );
  }

  void _showDeleteDialog(ShopItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.neonRed)),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding/editing shop items
class AddEditItemSheet extends StatefulWidget {
  final ShopItem? item;
  
  const AddEditItemSheet({super.key, this.item});

  @override
  State<AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends State<AddEditItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  String _selectedCategory = 'power_ups';
  String _selectedCurrency = 'coins';
  bool _isCosmetic = false;
  
  // Image upload
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.cost.toString() ?? '');
    _quantityController = TextEditingController(text: widget.item?.quantity.toString() ?? '1');
    _selectedCategory = widget.item?.category ?? 'power_ups';
    _selectedCurrency = widget.item?.costsCoins ?? true ? 'coins' : 'gems';
    _isCosmetic = widget.item?.isCosmetic ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isUploading = true;
        });

        // Upload to ImageBB
        final url = await ImgBBService.uploadFile(_selectedImage!);

        if (url != null) {
          setState(() {
            _uploadedImageUrl = url;
            _isUploading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Image uploaded successfully!'),
                backgroundColor: AppColors.neonGreen,
              ),
            );
          }
        } else {
          setState(() => _isUploading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Image upload failed. Try again.'),
                backgroundColor: AppColors.neonRed,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      debugPrint('Image picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    widget.item != null ? 'Edit Item' : 'Add New Item',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Image Upload Section
              _buildImageUploadSection(),
              const SizedBox(height: 20),

              // Name
              _buildTextField(
                controller: _nameController,
                label: 'Item Name',
                hint: 'e.g., 50-50 Lifeline',
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descController,
                label: 'Description',
                hint: 'e.g., Removes 2 wrong options',
                icon: Icons.description_rounded,
              ),
              const SizedBox(height: 16),

              // Category
              _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: const [
                  {'value': 'power_ups', 'label': '🎮 Power-Ups'},
                  {'value': 'shields', 'label': '🛡️ Shields'},
                  {'value': 'boosters', 'label': '⚡ Boosters'},
                  {'value': 'avatars', 'label': '🎨 Avatars'},
                  {'value': 'badges', 'label': '🏆 Badges'},
                  {'value': 'effects', 'label': '✨ Effects'},
                  {'value': 'packs', 'label': '🎁 Packs'},
                ],
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              // Price & Currency Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price',
                      hint: '150',
                      icon: Icons.monetization_on_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Currency',
                      value: _selectedCurrency,
                      items: const [
                        {'value': 'coins', 'label': '💰 Coins'},
                        {'value': 'gems', 'label': '💎 Gems'},
                      ],
                      onChanged: (value) => setState(() => _selectedCurrency = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity
              _buildTextField(
                controller: _quantityController,
                label: 'Quantity per purchase',
                hint: '1',
                icon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Is Cosmetic
              SwitchListTile(
                title: const Text(
                  'Cosmetic Item',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'One-time unlock (cannot buy again)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                value: _isCosmetic,
                onChanged: (value) => setState(() => _isCosmetic = value),
                activeColor: AppColors.neonCyan,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.item != null ? 'Update Item' : 'Add Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _uploadedImageUrl != null
              ? AppColors.neonGreen.withValues(alpha: 0.5)
              : AppColors.neonCyan.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Preview or Upload UI
          if (_selectedImage != null) ...[
            // Image Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(color: AppColors.neonCyan),
                  SizedBox(height: 8),
                  Text(
                    'Uploading to ImageBB...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              )
            else if (_uploadedImageUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Uploaded!',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text('Change'),
                  ),
                ],
              )
            else
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Upload'),
              ),
          ] else ...[
            // Upload Prompt
            Icon(
              Icons.cloud_upload_rounded,
              size: 48,
              color: AppColors.neonCyan.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload Item Icon',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Max 32MB • PNG, JPG, GIF',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // ImageBB URL display
          if (_uploadedImageUrl != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: AppColors.neonCyan, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _uploadedImageUrl!,
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonCyan),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'This field is required';
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      dropdownColor: AppColors.surfaceElevated,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
    );
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save to Firestore with _uploadedImageUrl
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.item != null ? '✅ Item updated!' : '✅ Item added!'),
          backgroundColor: AppColors.neonGreen,
        ),
      );
    }
  }
}
