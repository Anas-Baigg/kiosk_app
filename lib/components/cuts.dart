import 'package:kiosk_app/services/database_service.dart';

class Cuts {
  final String id;
  final String cutname;
  final double? price;
  final String? shopId;
  final bool isActive;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  Cuts({
    required this.id,
    required this.cutname,
    required this.price,
    this.shopId,
    this.createdAt,
    this.isActive = true,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DatabaseService.colCutId: id,
      DatabaseService.colCut: cutname,
      DatabaseService.colShopId: shopId,
      DatabaseService.colPrice: price,
      DatabaseService.colIsActive: isActive ? 1 : 0,
      DatabaseService.colCreatedAt: (createdAt ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      DatabaseService.colLastSynced: lastSyncedAt?.toUtc().toIso8601String(),
    };

    return map;
  }

  static Cuts fromMap(Map<String, dynamic> m) {
    return Cuts(
      id: m[DatabaseService.colCutId] as String,
      shopId: m[DatabaseService.colShopId] as String,
      cutname: m[DatabaseService.colCut] as String,
      price: (m[DatabaseService.colPrice] as num).toDouble(),
      isActive: m[DatabaseService.colIsActive] == 1,
      createdAt: m[DatabaseService.colCreatedAt] != null
          ? DateTime.parse(m[DatabaseService.colCreatedAt] as String).toLocal()
          : null,
      lastSyncedAt: m[DatabaseService.colLastSynced] != null
          ? DateTime.parse(m[DatabaseService.colLastSynced] as String).toLocal()
          : null,
    );
  }
}
