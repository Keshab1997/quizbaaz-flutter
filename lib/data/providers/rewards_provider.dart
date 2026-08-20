import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_assets.dart';
import '../models/gift_claim.dart';

/// Manages the player's won prizes and their claim/delivery state.
class RewardsProvider extends ChangeNotifier {
  static const _kGifts = 'quizbaaz_gift_claims';

  List<GiftClaim> _gifts = [];

  List<GiftClaim> get gifts => List.unmodifiable(_gifts);

  /// Default demo prizes (until a real backend dispatches them).
  static List<GiftClaim> _defaultGifts() {
    return [
      GiftClaim(
        id: 'gift_smartwatch',
        title: 'Fire-Boltt 3D Smartwatch',
        type: GiftType.physical,
        icon: AppAssets.giftBox,
        date: 'Aug 19',
      ),
      GiftClaim(
        id: 'gift_voucher',
        title: '₹500 Amazon Gift Voucher',
        type: GiftType.digital,
        icon: AppAssets.coinGem,
        date: 'Aug 15',
        digitalCode: 'AMZN-QUIZ-9981',
      ),
    ];
  }

  /// Loads persisted claim state (called once at app startup).
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kGifts);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _gifts = decoded
            .map((e) => GiftClaim.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _gifts = _defaultGifts();
      }
    } catch (e) {
      debugPrint('Failed to load gift claims: $e');
      _gifts = _defaultGifts();
    }
    notifyListeners();
  }

  /// Claims a physical gift with the supplied delivery address.
  bool claimPhysicalGift(
    String id, {
    required String name,
    required String phone,
    required String address,
    required String pincode,
  }) {
    final gift = _find(id);
    if (gift == null || gift.isClaimed) return false;

    gift.status = ClaimStatus.processing;
    gift.addressName = name;
    gift.addressPhone = phone;
    gift.addressLine = address;
    gift.addressPincode = pincode;
    notifyListeners();
    _persist();
    return true;
  }

  /// Redeems a digital gift code (marks it claimed).
  bool redeemDigitalGift(String id) {
    final gift = _find(id);
    if (gift == null || gift.isClaimed) return false;

    gift.status = ClaimStatus.delivered; // digital = instant delivery
    notifyListeners();
    _persist();
    return true;
  }

  GiftClaim? _find(String id) {
    for (final g in _gifts) {
      if (g.id == id) return g;
    }
    return null;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kGifts,
        jsonEncode(_gifts.map((g) => g.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Failed to persist gift claims: $e');
    }
  }
}
