import 'package:kiosk_app/services/database_service.dart';

class Product {
  final String id;
  final String productName;
  final double? price;
  final String? shopId;
  final bool isActive;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.productName,
    required this.price,
    this.isActive = true,
    this.shopId,
    this.createdAt,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DatabaseService.colProductId: id,
      DatabaseService.colShopId: shopId,
      DatabaseService.colProduct: productName,
      DatabaseService.colPrice: price,
      DatabaseService.colIsActive: isActive ? 1 : 0,
      DatabaseService.colCreatedAt: (createdAt ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      DatabaseService.colLastSynced: lastSyncedAt?.toUtc().toIso8601String(),
    };

    return map;
  }

  static Product fromMap(Map<String, dynamic> m) {
    return Product(
      id: m[DatabaseService.colProductId] as String,
      shopId: m[DatabaseService.colShopId] as String,
      productName: m[DatabaseService.colProduct] as String,
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
