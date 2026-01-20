import 'package:kiosk_app/services/database_service.dart';

class Employees {
  final String id;
  final String? shopId;
  final String name;
  final int passcode;
  final bool isActive;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  Employees({
    required this.id,
    this.shopId,
    required this.name,
    required this.passcode,
    this.isActive = true,
    this.lastSyncedAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      DatabaseService.colEmployeeId: id,
      DatabaseService.colName: name,
      DatabaseService.colShopId: shopId,
      DatabaseService.colPasscode: passcode,
      DatabaseService.colIsActive: isActive ? 1 : 0,
      DatabaseService.colCreatedAt: (createdAt ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      DatabaseService.colLastSynced: lastSyncedAt?.toUtc().toIso8601String(),
    };
  }

  static Employees fromMap(Map<String, dynamic> m) {
    return Employees(
      id: m[DatabaseService.colEmployeeId] as String,
      shopId: m[DatabaseService.colShopId] as String?,
      name: m[DatabaseService.colName] as String,
      passcode: m[DatabaseService.colPasscode] as int,
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
