import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/database/database_service.dart';

class EmployeeRepository {
  final DatabaseService _db;
  EmployeeRepository(this._db);

  String get _shopId => AppState.requireShopId();

  Future<String?> getEmployeeIdByPasscode(String passcode) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseService.tableEmployee,
      columns: [DatabaseService.colEmployeeId],
      where:
          '${DatabaseService.colPasscode} = ? AND ${DatabaseService.colIsActive} = 1 AND ${DatabaseService.colShopId} = ?',
      whereArgs: [passcode, _shopId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first[DatabaseService.colEmployeeId] as String;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllActiveEmployees() async {
    final db = await _db.database;
    return db.query(
      DatabaseService.tableEmployee,
      columns: [DatabaseService.colEmployeeId, DatabaseService.colName],
      where:
          '${DatabaseService.colIsActive} = 1 AND ${DatabaseService.colShopId} = ?',
      whereArgs: [_shopId],
      orderBy: '${DatabaseService.colName} COLLATE NOCASE',
    );
  }

  Future<Map<String, double>> getEmployeeTipsForDate(
    String employeeId,
    DateTime date,
  ) async {
    final db = await _db.database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final startOfNextDay = DateTime(date.year, date.month, date.day + 1);
    final fromIso = startOfDay.toUtc().toIso8601String();
    final toIsoExclusive = startOfNextDay.toUtc().toIso8601String();

    final rows = await db.rawQuery(
      '''
      SELECT ${DatabaseService.colPaymentMethod}, SUM(${DatabaseService.colTip}) as total_tip
      FROM ${DatabaseService.tableTransactions}
      WHERE ${DatabaseService.colTransactionEmpId} = ?
        AND ${DatabaseService.colShopId} = ?
        AND ${DatabaseService.colCreatedAt} >= ?
        AND ${DatabaseService.colCreatedAt} < ?
      GROUP BY ${DatabaseService.colPaymentMethod}
      ''',
      [employeeId, _shopId, fromIso, toIsoExclusive],
    );

    double cashTips = 0.0;
    double cardTips = 0.0;
    for (var row in rows) {
      final method =
          (row[DatabaseService.colPaymentMethod] as String).toLowerCase();
      final total = (row['total_tip'] as num?)?.toDouble() ?? 0.0;
      if (method.contains('cash')) {
        cashTips += total;
      } else {
        cardTips += total;
      }
    }
    return {'Cash': cashTips, 'Card': cardTips};
  }
}
