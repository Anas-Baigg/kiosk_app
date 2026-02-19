import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_service.dart';

class PullService {
  final _supabase = Supabase.instance.client;
  final _dbService = DatabaseService.instance;

  String get currentShopId => AppState.requireShopId();

  Future<bool> fullDownloadFromCloud({int historyDays = 30}) async {
    debugPrint("Starting Full Sync: Downloading then Pruning...");

    try {
      //Reference data
      await downloadEmployees();
      await downloadProducts();
      await downloadCuts();

      //History window
      await downloadRecentHistory(historyDays: historyDays);

      // prune AFTER successful pull
      await _dbService.purgeOldHistory(keepDays: historyDays);

      debugPrint("Full Sync complete.");
      return true;
    } catch (e) {
      debugPrint("Full sync failed: $e");
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

  Future<void> downloadRecentHistory({int historyDays = 60}) async {
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

  /// Local unsynced = last_synced_at IS NULL.
  Future<void> _safeUpsertMany({
    required Database db,
    required String localTable,
    required String idColumn,
    required List<Map<String, dynamic>> rows,
    bool normalizeIsActive = false,
  }) async {
    if (rows.isEmpty) return;

    // enforce correct shop_id in all rows
    for (final row in rows) {
      row[DatabaseService.colShopId] = currentShopId;

      if (normalizeIsActive && row.containsKey(DatabaseService.colIsActive)) {
        row[DatabaseService.colIsActive] =
            (row[DatabaseService.colIsActive] == true) ? 1 : 0;
      }
    }

    await db.transaction((txn) async {
      for (final row in rows) {
        final id = row[idColumn];
        if (id == null) continue;

        // Check if local row exists AND is unsynced (protected)
        final local = await txn.query(
          localTable,
          columns: [DatabaseService.colLastSynced],
          where: '$idColumn = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [id, currentShopId],
          limit: 1,
        );

        final localHasUnsynced =
            local.isNotEmpty &&
            local.first[DatabaseService.colLastSynced] == null;

        if (localHasUnsynced) {
          // Do NOT overwrite local unsynced changes
          continue;
        }

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
