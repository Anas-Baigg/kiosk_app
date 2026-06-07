import 'package:intl/intl.dart';
import 'package:kiosk_app/services/database_service.dart';

class TillBalance {
  final String id;
  final DateTime balanceDate;
  final double balanceAmount;
  final String? shopId;
  final DateTime? lastSyncedAt;

  TillBalance({
    required this.id,
    required this.balanceAmount,
    required this.balanceDate,
    this.shopId,
    this.lastSyncedAt,
  });
  static final _dateonlyFmt = DateFormat('yyyy-MM-dd');
  Map<String, dynamic> toMap() {
    return {
      DatabaseService.colTillBalanceId: id,
      DatabaseService.colBalanceAmount: balanceAmount,
      DatabaseService.colTillDate: _dateonlyFmt.format(balanceDate),
      DatabaseService.colLastSynced: lastSyncedAt?.toUtc().toIso8601String(),
      DatabaseService.colShopId: shopId,
    };
  }

  factory TillBalance.fromMap(Map<String, dynamic> map) {
    final raw = map[DatabaseService.colTillDate] as String;
    DateTime parseTillDate(String s) {
      final parts = s.split('-').map(int.parse).toList();
      return DateTime(parts[0], parts[1], parts[2]);
    }

    return TillBalance(
      id: map[DatabaseService.colTillBalanceId] as String,
      balanceAmount: (map[DatabaseService.colBalanceAmount] as num).toDouble(),
      balanceDate: parseTillDate(raw),
      lastSyncedAt: map[DatabaseService.colLastSynced] != null
          ? DateTime.parse(
              map[DatabaseService.colLastSynced] as String,
            ).toLocal()
          : null,
    );
  }
}
