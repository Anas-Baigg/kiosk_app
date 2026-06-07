import 'package:kiosk_app/models/transaction_item.dart';
import 'package:kiosk_app/models/transaction_model.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final DatabaseService _db;
  TransactionRepository(this._db);

  String get _shopId => AppState.requireShopId();

  Future<String> saveTransactionObjects(
    TransactionHeader header,
    List<TransactionItem> items,
  ) async {
    final db = await _db.database;
    final uuid = const Uuid();
    final transactionId = uuid.v4();

    final headerWithId = TransactionHeader(
      id: transactionId,
      employeeId: header.employeeId,
      baseTotal: header.baseTotal,
      tip: header.tip,
      discount: header.discount,
      finalTotal: header.finalTotal,
      paymentMethod: header.paymentMethod,
      timestamp: header.timestamp,
      shopId: header.shopId,
      lastSyncedAt: header.lastSyncedAt,
    );

    await db.transaction((txn) async {
      final headerMap = headerWithId.toMap();
      headerMap[DatabaseService.colLastSynced] = null;
      await txn.insert(
        DatabaseService.tableTransactions,
        headerMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final item in items) {
        final itemWithIds = TransactionItem(
          id: uuid.v4(),
          transactionId: transactionId,
          itemType: item.itemType,
          itemName: item.itemName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          shopId: item.shopId,
          lastSyncedAt: item.lastSyncedAt,
        );
        final itemMap = itemWithIds.toMap();
        itemMap[DatabaseService.colLastSynced] = null;
        await txn.insert(
          DatabaseService.tableTransactionItems,
          itemMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return transactionId;
  }

  Future<List<TransactionHeader>> getTransactionsBetweenDates({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db.database;

    final startOfFromDay = DateTime(from.year, from.month, from.day);
    final startOfDayAfterTo = DateTime(to.year, to.month, to.day + 1);
    final fromMs = startOfFromDay.toUtc().toIso8601String();
    final toMsExclusive = startOfDayAfterTo.toUtc().toIso8601String();

    final rows = await db.rawQuery(
      '''
      SELECT
        t.*,
        e.${DatabaseService.colName} AS employeeName
      FROM ${DatabaseService.tableTransactions} t
      LEFT JOIN ${DatabaseService.tableEmployee} e
        ON t.${DatabaseService.colTransactionEmpId} = e.${DatabaseService.colEmployeeId}
      WHERE t.${DatabaseService.colShopId} = ?
        AND t.${DatabaseService.colCreatedAt} >= ? AND t.${DatabaseService.colCreatedAt} < ?
      ORDER BY t.${DatabaseService.colCreatedAt} DESC
      ''',
      [_shopId, fromMs, toMsExclusive],
    );

    return rows.map((map) => TransactionHeader.fromMap(map)).toList();
  }

  Future<List<TransactionItem>> getItemsForTransaction(
    String transactionId,
  ) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseService.tableTransactionItems,
      where:
          '${DatabaseService.colItemTransactionId} = ? AND ${DatabaseService.colShopId} = ?',
      whereArgs: [transactionId, _shopId],
    );
    return List.generate(maps.length, (i) => TransactionItem.fromMap(maps[i]));
  }
}
