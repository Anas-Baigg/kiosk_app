import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_service.dart';

class PullService {
  final _supabase = Supabase.instance.client;
  final _dbService = DatabaseService.instance;

  String get currentShopId => AppState.requireShopId();

  Future<bool> fullDownloadFromCloud({int historyDays = 30}) async {
    AppLogger.sync("Starting Full Sync: Downloading then Pruning...");

    try {
      //Reference data
      await downloadEmployees();
      await downloadProducts();
      await downloadCuts();

      //History window
      await downloadRecentHistory(historyDays: historyDays);

      // prune AFTER successful pull
      await _dbService.purgeOldHistory(keepDays: historyDays);

      AppLogger.sync("Full Sync complete.");
      return true;
    } catch (e) {
      AppLogger.error("Full sync failed", e);
      return false;
    }
  }

  Future<void> downloadEmployees() async {
    await _downloadReferenceTableSafe(
      remoteTable: 'employee',
      localTable: DatabaseService.tableEmployee,
      idColumn: DatabaseService.colEmployeeId,
      normalizeIsActive: true,
    );
  }

  Future<void> downloadProducts() async {
    await _downloadReferenceTableSafe(
      remoteTable: 'products',
      localTable: DatabaseService.tableProducts,
      idColumn: DatabaseService.colProductId,
      normalizeIsActive: true,
    );
  }

  Future<void> downloadCuts() async {
    await _downloadReferenceTableSafe(
      remoteTable: 'cuts',
      localTable: DatabaseService.tableCuts,
      idColumn: DatabaseService.colCutId,
      normalizeIsActive: true,
    );
  }

  Future<void> downloadRecentHistory({int historyDays = 30}) async {
    final db = await _dbService.database;
    final cutoffIso = DateTime.now()
        .toUtc()
        .subtract(Duration(days: historyDays))
        .toIso8601String();

    // A) Transactions
    final txData = await _supabase
        .from('transactions')
        .select()
        .eq('shop_id', currentShopId)
        .gte('created_at', cutoffIso);

    final txList = txData.map((e) => Map<String, dynamic>.from(e)).toList();

    await _safeUpsertMany(
      db: db,
      localTable: DatabaseService.tableTransactions,
      idColumn: DatabaseService.colTransactionId,
      rows: txList,
    );

    // B) Items for downloaded tx ids
    if (txList.isNotEmpty) {
      final txIds = txList.map((m) => m['id']).whereType<String>().toList();
      final allItems = <Map<String, dynamic>>[];

      for (final chunk in _chunks(txIds, 200)) {
        final itemData = await _supabase
            .from('transaction_items')
            .select()
            .eq('shop_id', currentShopId)
            .inFilter('transaction_id', chunk);

        allItems.addAll(itemData.map((e) => Map<String, dynamic>.from(e)));
      }

      await _safeUpsertMany(
        db: db,
        localTable: DatabaseService.tableTransactionItems,
        idColumn: DatabaseService.colTransactionItemId,
        rows: allItems,
      );
    }

    // C) Time logs
    final logData = await _supabase
        .from('time_logs')
        .select()
        .eq('shop_id', currentShopId)
        .gte('clock_in_time', cutoffIso);

    final logList = logData.map((e) => Map<String, dynamic>.from(e)).toList();

    await _safeUpsertMany(
      db: db,
      localTable: DatabaseService.tableTime,
      idColumn: DatabaseService.colLogId,
      rows: logList,
    );

    // D) Till balance (note: your remote filter uses balance_date; ensure types match)
    final tillData = await _supabase
        .from('till_balance')
        .select()
        .eq('shop_id', currentShopId)
        .gte('balance_date', cutoffIso);

    final tillList = tillData.map((e) => Map<String, dynamic>.from(e)).toList();

    await _safeUpsertMany(
      db: db,
      localTable: DatabaseService.tableTillBalance,
      idColumn: DatabaseService.colTillBalanceId,
      rows: tillList,
    );
  }

  // ---------------- Safe pull helpers ----------------

  Future<void> _downloadReferenceTableSafe({
    required String remoteTable,
    required String localTable,
    required String idColumn,
    bool normalizeIsActive = false,
  }) async {
    final db = await _dbService.database;

    final data = await _supabase
        .from(remoteTable)
        .select()
        .eq('shop_id', currentShopId);

    final rows = data.map((e) => Map<String, dynamic>.from(e)).toList();

    await _safeUpsertMany(
      db: db,
      localTable: localTable,
      idColumn: idColumn,
      rows: rows,
      normalizeIsActive: normalizeIsActive,
    );
  }

  /// Upserts rows downloaded from Supabase into the local table.
  /// Skips rows that have unsynced local edits (last_synced_at IS NULL locally).
  /// Stamps last_synced_at = now() on every row that IS inserted so the sync
  /// service does not immediately treat downloaded data as pending upload.
  Future<void> _safeUpsertMany({
    required Database db,
    required String localTable,
    required String idColumn,
    required List<Map<String, dynamic>> rows,
    bool normalizeIsActive = false,
  }) async {
    if (rows.isEmpty) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();

    for (final row in rows) {
      row[DatabaseService.colShopId] = currentShopId;
      if (normalizeIsActive && row.containsKey(DatabaseService.colIsActive)) {
        row[DatabaseService.colIsActive] =
            (row[DatabaseService.colIsActive] == true) ? 1 : 0;
      }
    }

    final ids = rows.map((r) => r[idColumn]).whereType<String>().toList();

    await db.transaction((txn) async {
      // Batch-fetch existing local rows to check for unsynced data — one query
      // per 200-row chunk instead of N individual SELECTs.
      final Map<String, bool> unsyncedById = {};
      for (final chunk in _chunks(ids, 200)) {
        final placeholders = chunk.map((_) => '?').join(',');
        final existing = await txn.rawQuery(
          'SELECT $idColumn, ${DatabaseService.colLastSynced} '
          'FROM $localTable '
          'WHERE $idColumn IN ($placeholders) AND ${DatabaseService.colShopId} = ?',
          [...chunk, currentShopId],
        );
        for (final r in existing) {
          final id = r[idColumn] as String?;
          if (id != null) {
            unsyncedById[id] = r[DatabaseService.colLastSynced] == null;
          }
        }
      }

      for (final row in rows) {
        final id = row[idColumn] as String?;
        if (id == null) continue;
        if (unsyncedById[id] == true) continue; // protect local unsynced edits

        // Mark as synced: data came from the server.
        row[DatabaseService.colLastSynced] = nowIso;

        await txn.insert(
          localTable,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Iterable<List<T>> _chunks<T>(List<T> input, int size) sync* {
    for (var i = 0; i < input.length; i += size) {
      yield input.sublist(i, i + size > input.length ? input.length : i + size);
    }
  }
}
