import 'package:kiosk_app/models/time_log.dart';
import 'package:kiosk_app/models/time_log_display.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/database/database_service.dart';
import 'package:uuid/uuid.dart';

class TimeLogRepository {
  final DatabaseService _db;
  TimeLogRepository(this._db);

  String get _shopId => AppState.requireShopId();

  Future<Map<String, dynamic>?> _getLatestOpenLog(dynamic employeeId) async {
    final db = await _db.database;
    final res = await db.query(
      DatabaseService.tableTime,
      where:
          '${DatabaseService.logEmp} = ? AND ${DatabaseService.clockout} IS NULL AND ${DatabaseService.colShopId} = ?',
      whereArgs: [employeeId, _shopId],
      orderBy: '${DatabaseService.clockin} DESC',
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<int> clockIn(dynamic employeeId) async {
    final db = await _db.database;
    final latestOpenLog = await _getLatestOpenLog(employeeId);
    final nowLocal = DateTime.now();
    final uuid = const Uuid();

    if (latestOpenLog == null) {
      return db.insert(
        DatabaseService.tableTime,
        TimeLog(
          id: uuid.v4(),
          employeeId: employeeId,
          clockIn: nowLocal,
          clockOut: null,
          shopId: _shopId,
        ).toMap(),
      );
    }

    final clockInString = latestOpenLog[DatabaseService.clockin] as String;
    final clockInTimeLocal = DateTime.parse(clockInString).toLocal();

    final bool isFromToday =
        clockInTimeLocal.year == nowLocal.year &&
        clockInTimeLocal.month == nowLocal.month &&
        clockInTimeLocal.day == nowLocal.day;

    if (isFromToday) {
      return -1;
    } else {
      final endOfOldDayLocal = DateTime(
        clockInTimeLocal.year,
        clockInTimeLocal.month,
        clockInTimeLocal.day,
        23,
        59,
        59,
      );
      final autoClockOutIso = endOfOldDayLocal.toUtc().toIso8601String();
      final oldLogId = latestOpenLog[DatabaseService.colLogId] as String;

      return db.transaction((txn) async {
        await txn.update(
          DatabaseService.tableTime,
          {DatabaseService.clockout: autoClockOutIso, DatabaseService.colLastSynced: null},
          where: '${DatabaseService.colLogId} = ?',
          whereArgs: [oldLogId],
        );
        return txn.insert(
          DatabaseService.tableTime,
          TimeLog(
            id: uuid.v4(),
            employeeId: employeeId,
            clockIn: nowLocal,
            clockOut: null,
            shopId: _shopId,
          ).toMap(),
        );
      });
    }
  }

  Future<bool> clockOut(dynamic employeeId) async {
    final db = await _db.database;
    final openLog = await _getLatestOpenLog(employeeId);
    if (openLog == null) return false;

    final openId = openLog[DatabaseService.colLogId] as String;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final count = await db.update(
      DatabaseService.tableTime,
      {DatabaseService.clockout: nowIso, DatabaseService.colLastSynced: null},
      where: '${DatabaseService.colLogId} = ?',
      whereArgs: [openId],
    );
    return count > 0;
  }

  Future<List<Map<String, dynamic>>> getActiveEmployees() async {
    final db = await _db.database;
    return db.rawQuery(
      '''
      SELECT e.${DatabaseService.colEmployeeId}, e.${DatabaseService.colName}
      FROM ${DatabaseService.tableTime} t
      JOIN ${DatabaseService.tableEmployee} e ON e.${DatabaseService.colEmployeeId} = t.${DatabaseService.logEmp}
      WHERE t.${DatabaseService.clockout} IS NULL
        AND t.${DatabaseService.colShopId} = ?
        AND date(t.${DatabaseService.clockin}, 'utc', 'localtime') = date('now', 'localtime')
      GROUP BY e.${DatabaseService.colEmployeeId}, e.${DatabaseService.colName}
      ORDER BY e.${DatabaseService.colName} COLLATE NOCASE
      ''',
      [_shopId],
    );
  }

  Future<List<TimeLogDisplay>> getTimeLogsBetweenDates({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db.database;

    final startOfFromDay = DateTime(from.year, from.month, from.day);
    final startOfDayAfterTo = DateTime(to.year, to.month, to.day + 1);
    final fromIso = startOfFromDay.toUtc().toIso8601String();
    final toIsoExclusive = startOfDayAfterTo.toUtc().toIso8601String();

    final rows = await db.rawQuery(
      '''
      SELECT
        t.${DatabaseService.colLogId} AS log_id,
        t.${DatabaseService.logEmp} AS employee_id,
        e.${DatabaseService.colName} AS employee_name,
        t.${DatabaseService.clockin} AS clock_in,
        t.${DatabaseService.clockout} AS clock_out
      FROM ${DatabaseService.tableTime} t
      JOIN ${DatabaseService.tableEmployee} e ON e.${DatabaseService.colEmployeeId} = t.${DatabaseService.logEmp}
      WHERE t.${DatabaseService.colShopId} = ?
        AND t.${DatabaseService.clockin} >= ? AND t.${DatabaseService.clockin} < ?
      ORDER BY t.${DatabaseService.clockin} ASC
      ''',
      [_shopId, fromIso, toIsoExclusive],
    );

    return rows.map((row) => TimeLogDisplay.fromMap(row)).toList();
  }
}
