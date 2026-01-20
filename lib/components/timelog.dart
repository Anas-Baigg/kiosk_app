import 'package:kiosk_app/services/database_service.dart';

class TimeLog {
  final String id;
  final String employeeId;
  final DateTime clockIn;
  final DateTime? clockOut;
  final String? shopId;
  final DateTime? lastSyncedAt;

  TimeLog({
    required this.id,
    required this.employeeId,
    required this.clockIn,
    this.clockOut,
    this.shopId,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() => {
    DatabaseService.colLogId: id,
    DatabaseService.logEmp: employeeId,
    DatabaseService.clockin: clockIn.toUtc().toIso8601String(),
    DatabaseService.clockout: clockOut?.toUtc().toIso8601String(),
    DatabaseService.colShopId: shopId,
    DatabaseService.colLastSynced: lastSyncedAt?.toUtc().toIso8601String(),
  };
}
