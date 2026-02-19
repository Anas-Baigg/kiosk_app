import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final _supabase = Supabase.instance.client;
  final _dbService = DatabaseService.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool _isSyncing = false;

  // Debounce connectivity-triggered sync
  Timer? _debounceTimer;

  // ---------- Safe getters / guards ----------

  String? get _shopIdSafe {
    final id = AppState.shopId;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  // ---------- Public API ----------

  /// Call once ideally after Supabase init Safe to call multiple times.
  void initConnectivityMonitoring() {
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (!hasNetwork) return;

      // If shop isn't selected yet, do nothing (prevents requireShopId crash)
      if (_shopIdSafe == null) return;

      // Debounce multiple events
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () async {
        debugPrint("Connection restored: Triggering auto-sync...");
        await syncAll();
      });
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  //check than connectivity_plus alone.

  Future<bool> isOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return false;

    // If shop not selected we cant sync anyway.
    if (_shopIdSafe == null) return false;

    try {
      //any quick select works.
      await _supabase.from('shops').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Manual sync button uses this.
  Future<bool> syncAll() async {
    final shopId = _shopIdSafe;
    if (shopId == null) return false;

    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      if (!await isOnline()) return false;

      // Order matters
      await syncEmployees();
      await syncProducts();
      await syncCuts();
      await syncTimeLogs();
      await syncTransactions();
      await syncTillbalance();

      return true;
    } catch (e) {
      debugPrint("Sync failed: $e");
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // ---------- Table sync methods ----------

  Future<void> syncEmployees() async {
    await _syncSimpleTable(
      remoteTable: 'employee',
      localTable: DatabaseService.tableEmployee,
      idColumn: DatabaseService.colEmployeeId,
    );
  }

  Future<void> syncProducts() async {
    await _syncSimpleTable(
      remoteTable: 'products',
      localTable: DatabaseService.tableProducts,
      idColumn: DatabaseService.colProductId,
    );
  }

  Future<void> syncCuts() async {
    await _syncSimpleTable(
      remoteTable: 'cuts',
      localTable: DatabaseService.tableCuts,
      idColumn: DatabaseService.colCutId,
    );
  }

  Future<void> syncTimeLogs() async {
    await _syncSimpleTable(
      remoteTable: 'time_logs',
      localTable: DatabaseService.tableTime,
      idColumn: DatabaseService.colLogId,
    );
  }

  Future<void> syncTillbalance() async {
    await _syncSimpleTable(
      remoteTable: 'till_balance',
      localTable: DatabaseService.tableTillBalance,
      idColumn: DatabaseService.colTillBalanceId,
    );
  }

  Future<void> syncTransactions() async {
    final shopId = _shopIdSafe;
    if (shopId == null) return;

    if (_isSyncing) return;
    _isSyncing = true;

    final db = await _dbService.database;

    try {
      if (!await isOnline()) return;

      //Get unsynced headers
      final unsyncedHeaders = await db.query(
        DatabaseService.tableTransactions,
        where:
            '${DatabaseService.colLastSynced} IS NULL AND ${DatabaseService.colShopId} = ?',
        whereArgs: [shopId],
      );
      if (unsyncedHeaders.isEmpty) return;

      final txIds = unsyncedHeaders
          .map((h) => h[DatabaseService.colTransactionId])
          .whereType<String>()
          .toList();

      // Load all items for these txIds
      final allItems = <Map<String, dynamic>>[];
      for (final chunk in _chunks(txIds, 200)) {
        final items = await db.query(
          DatabaseService.tableTransactionItems,
          where:
              '${DatabaseService.colItemTransactionId} IN (${_placeholders(chunk.length)}) AND ${DatabaseService.colShopId} = ? AND ${DatabaseService.colLastSynced} IS NULL',
          whereArgs: [...chunk, shopId],
        );
        allItems.addAll(items);
      }

      //Upload headers & items
      await _supabase.from('transactions').upsert(unsyncedHeaders);
      if (allItems.isNotEmpty) {
        await _supabase.from('transaction_items').upsert(allItems);
      }

      //Mark synced ATOMICALLY
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await db.transaction((txn) async {
        // Mark all headers synced
        for (final chunk in _chunks(txIds, 200)) {
          await txn.update(
            DatabaseService.tableTransactions,
            {DatabaseService.colLastSynced: nowIso},
            where:
                '${DatabaseService.colTransactionId} IN (${_placeholders(chunk.length)}) AND ${DatabaseService.colShopId} = ?',
            whereArgs: [...chunk, shopId],
          );
        }

        // Mark all items synced for those txIds
        if (allItems.isNotEmpty) {
          for (final chunk in _chunks(txIds, 200)) {
            await txn.update(
              DatabaseService.tableTransactionItems,
              {DatabaseService.colLastSynced: nowIso},
              where:
                  '${DatabaseService.colItemTransactionId} IN (${_placeholders(chunk.length)}) AND ${DatabaseService.colShopId} = ?',
              whereArgs: [...chunk, shopId],
            );
          }
        }
      });
    } on AuthException catch (e) {
      debugPrint("Auth error syncing transactions: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Error syncing transactions: $e");
    } finally {
      _isSyncing = false;
    }
  }

  // ---------- Generic helpers ----------

  Future<void> _syncSimpleTable({
    required String remoteTable,
    required String localTable,
    required String idColumn,
  }) async {
    final shopId = _shopIdSafe;
    if (shopId == null) return;

    // Prevent collisions with other syncs
    if (_isSyncing) return;
    _isSyncing = true;

    final db = await _dbService.database;

    try {
      if (!await isOnline()) return;

      final unsyncedRows = await db.query(
        localTable,
        where:
            '${DatabaseService.colLastSynced} IS NULL AND ${DatabaseService.colShopId} = ?',
        whereArgs: [shopId],
      );

      if (unsyncedRows.isEmpty) return;

      await _supabase.from(remoteTable).upsert(unsyncedRows);

      final ids = unsyncedRows
          .map((r) => r[idColumn])
          .whereType<String>()
          .toList();
      final nowIso = DateTime.now().toUtc().toIso8601String();

      await db.transaction((txn) async {
        for (final chunk in _chunks(ids, 200)) {
          await txn.update(
            localTable,
            {DatabaseService.colLastSynced: nowIso},
            where:
                '$idColumn IN (${_placeholders(chunk.length)}) AND ${DatabaseService.colShopId} = ?',
            whereArgs: [...chunk, shopId],
          );
        }
      });
    } on AuthException catch (e) {
      debugPrint("Auth error syncing $remoteTable: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Error syncing $remoteTable: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Iterable<List<T>> _chunks<T>(List<T> input, int size) sync* {
    for (var i = 0; i < input.length; i += size) {
      yield input.sublist(i, i + size > input.length ? input.length : i + size);
    }
  }

  String _placeholders(int count) => List.filled(count, '?').join(',');
}
