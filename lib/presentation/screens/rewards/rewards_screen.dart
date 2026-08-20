import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/models/gift_claim.dart';
import '../../../data/providers/rewards_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardsProvider>();
    final gifts = rewards.gifts;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Rewards & Gifts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Banner
          GlassCard(
            borderRadius: 20,
            borderColor: AppColors.neonGold.withValues(alpha: 0.4),
            backgroundColor: const Color(0x33281E48),
            child: Row(
              children: [
                Image.asset(
                  AppAssets.rewardGirl,
                  width: 84,
                  height: 84,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    AppAssets.giftBox,
                    width: 70,
                    height: 70,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Win Daily Real Gifts!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonGold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Finish #1 in Daily Live Quiz to receive high-tech gadgets & vouchers delivered to your home.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'YOUR GIFTS & PRIZES',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a prize to claim or track it.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          if (gifts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No prizes yet — win the Daily Quiz! 🏆',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...gifts.map(
              (gift) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GiftCard(gift: gift),
              ),
            ),
        ],
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  final GiftClaim gift;

  const _GiftCard({required this.gift});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = _statusInfo(gift.status);

    return GlassCard(
      borderRadius: 18,
      onTap: () => _showClaimSheet(context),
      child: Row(
        children: [
          Image.asset(gift.icon, width: 48, height: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      gift.date,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            gift.isClaimed ? Icons.chevron_right : Icons.arrow_forward,
            size: 20,
            color: gift.isClaimed ? AppColors.textMuted : AppColors.neonGold,
          ),
        ],
      ),
    );
  }

  void _showClaimSheet(BuildContext context) {
    if (gift.isPhysical) {
      if (gift.isClaimed) {
        _showDeliverySheet(context);
      } else {
        _showAddressForm(context);
      }
    } else {
      _showDigitalSheet(context);
    }
  }

  void _showAddressForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(gift: gift),
    );
  }

  void _showDigitalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DigitalClaimSheet(gift: gift),
    );
  }

  void _showDeliverySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeliverySheet(gift: gift),
    );
  }
}

// ------------------------------------------------------------ Status helpers

(String, Color) _statusInfo(ClaimStatus status) {
  switch (status) {
    case ClaimStatus.unclaimed:
      return ('CLAIM NOW', AppColors.neonGold);
    case ClaimStatus.processing:
      return ('PROCESSING', AppColors.neonCyan);
    case ClaimStatus.shipped:
      return ('SHIPPED', AppColors.neonPurple);
    case ClaimStatus.delivered:
      return ('DELIVERED', AppColors.neonGreen);
  }
}

// ------------------------------------------------------- Physical claim form

class _AddressFormSheet extends StatefulWidget {
  final GiftClaim gift;

  const _AddressFormSheet({required this.gift});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _pincode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    context.read<RewardsProvider>().claimPhysicalGift(
          widget.gift.id,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          pincode: _pincode.text.trim(),
        );

    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('🎁 Gift claimed! We\'ll deliver it to your address.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Delivery Address', widget.gift.title),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField(
                  controller: _name,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                _buildField(
                  controller: _phone,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
                ),
                _buildField(
                  controller: _address,
                  label: 'Full Address (House, Street, Area)',
                  icon: Icons.home,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().length < 8) ? 'Enter your full address' : null,
                ),
                _buildField(
                  controller: _pincode,
                  label: 'PIN Code',
                  icon: Icons.local_post_office,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid PIN code' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NeonButton(
            text: 'SUBMIT & CLAIM 🎁',
            onPressed: _submitting ? () {} : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.neonCyan),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Digital claim

class _DigitalClaimSheet extends StatelessWidget {
  final GiftClaim gift;

  const _DigitalClaimSheet({required this.gift});

  @override
  Widget build(BuildContext context) {
    final code = gift.digitalCode ?? '—';

    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Digital Reward', gift.title),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Text(
                  'YOUR REDEEM CODE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonGold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Copy the code and redeem it on the partner site.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.neonCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard! 📋')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.neonCyan),
                  label: const Text('COPY CODE', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeonButton(
            text: gift.isClaimed ? 'CLAIMED ✓' : 'REDEEM & MARK CLAIMED',
            onPressed: gift.isClaimed
                ? () => Navigator.of(context).pop()
                : () {
                    context.read<RewardsProvider>().redeemDigitalGift(gift.id);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Code redeemed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Delivery info

class _DeliverySheet extends StatelessWidget {
  final GiftClaim gift;

  const _DeliverySheet({required this.gift});

  @override
  Widget build(BuildContext context) {
    final steps = ['Processing', 'Shipped', 'Delivered'];
    final currentIndex = switch (gift.status) {
      ClaimStatus.processing => 0,
      ClaimStatus.shipped => 1,
      ClaimStatus.delivered => 2,
      ClaimStatus.unclaimed => 0,
    };

    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetTitle('Delivery Status', gift.title),
          const SizedBox(height: 16),
          // Timeline
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIndex = i ~/ 2;
                final active = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: active ? AppColors.neonGreen : Colors.white12,
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final active = stepIndex <= currentIndex;
              return Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.neonGreen : Colors.white10,
                      border: Border.all(color: active ? AppColors.neonGreen : Colors.white24),
                    ),
                    child: Icon(
                      stepIndex < currentIndex ? Icons.check : Icons.circle,
                      size: 14,
                      color: active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[stepIndex],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.neonGreen : AppColors.textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          // Address summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DELIVERING TO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Text(
                  gift.addressName ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  gift.addressLine ?? '—',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'PIN: ${gift.addressPincode ?? '—'}  •  📞 ${gift.addressPhone ?? '—'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- Shared UI bits

Widget _sheetTitle(String heading, String sub) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        heading,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      const SizedBox(height: 2),
      Text(
        sub,
        style: const TextStyle(fontSize: 13, color: AppColors.neonGold),
      ),
    ],
  );
}

class _SheetScaffold extends StatelessWidget {
  final Widget child;

  const _SheetScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }
}
