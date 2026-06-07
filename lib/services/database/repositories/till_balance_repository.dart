import 'package:intl/intl.dart';
import 'package:kiosk_app/models/till_balance.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

class TillBalanceRepository {
  final DatabaseService _db;
  TillBalanceRepository(this._db);

  String get _shopId => AppState.requireShopId();

  Future<int> insertTillBalance(TillBalance balance) async {
    final db = await _db.database;
    return db.insert(
      DatabaseService.tableTillBalance,
      balance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TillBalance?> getTillBalanceByDate(DateTime date) async {
    final db = await _db.database;
    final d = DateFormat('yyyy-MM-dd').format(date);
    final rows = await db.query(
      DatabaseService.tableTillBalance,
      where:
          '${DatabaseService.colTillDate} = ? AND ${DatabaseService.colShopId} = ?',
      whereArgs: [d, _shopId],
    );
    if (rows.isNotEmpty) return TillBalance.fromMap(rows.first);
    return null;
  }

  Future<List<TillBalance>> getBalanceBetweenDates({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db.database;

    final startOfFromDay = DateTime(from.year, from.month, from.day);
    final startOfDayAfterTo = DateTime(to.year, to.month, to.day + 1);
    final fromStr = DateFormat('yyyy-MM-dd').format(startOfFromDay);
    final toStrExclusive = DateFormat('yyyy-MM-dd').format(startOfDayAfterTo);

    final rows = await db.query(
      DatabaseService.tableTillBalance,
      where:
          '${DatabaseService.colShopId} = ? AND ${DatabaseService.colTillDate} >= ? AND ${DatabaseService.colTillDate} < ?',
      whereArgs: [_shopId, fromStr, toStrExclusive],
    );
    return rows.map((row) => TillBalance.fromMap(row)).toList();
  }
}
