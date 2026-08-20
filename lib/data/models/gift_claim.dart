/// What kind of prize a gift is.
enum GiftType { physical, digital }

/// Lifecycle of a claimed gift.
enum ClaimStatus { unclaimed, processing, shipped, delivered }

/// A prize the player won, with its claim state.
class GiftClaim {
  final String id;
  final String title;
  final GiftType type;
  final String icon;

  /// When the gift was won (display string, e.g. "Aug 19").
  final String date;
  ClaimStatus status;

  /// Digital rewards: the redeemable code.
  String? digitalCode;

  /// Physical rewards: delivery address.
  String? addressName;
  String? addressPhone;
  String? addressLine;
  String? addressPincode;

  GiftClaim({
    required this.id,
    required this.title,
    required this.type,
    required this.icon,
    required this.date,
    this.status = ClaimStatus.unclaimed,
    this.digitalCode,
    this.addressName,
    this.addressPhone,
    this.addressLine,
    this.addressPincode,
  });

  bool get isPhysical => type == GiftType.physical;
  bool get isClaimed => status != ClaimStatus.unclaimed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'icon': icon,
      'date': date,
      'status': status.name,
      'digital_code': digitalCode,
      'address_name': addressName,
      'address_phone': addressPhone,
      'address_line': addressLine,
      'address_pincode': addressPincode,
    };
  }

  factory GiftClaim.fromJson(Map<String, dynamic> json) {
    return GiftClaim(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] == 'physical' ? GiftType.physical : GiftType.digital,
      icon: json['icon'] ?? '',
      date: json['date'] ?? '',
      status: ClaimStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ClaimStatus.unclaimed,
      ),
      digitalCode: json['digital_code'],
      addressName: json['address_name'],
      addressPhone: json['address_phone'],
      addressLine: json['address_line'],
      addressPincode: json['address_pincode'],
    );
  }
}
