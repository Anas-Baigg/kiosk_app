import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class SyncService {
  final _supabase = Supabase.instance.client;
  final _dbService = DatabaseService.instance;
  String get currentShopId => AppState.requireShopId();

  Future<void> syncTransactions() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> unsyncedHeaders = await db.query(
      DatabaseService.tableTransactions,
      where:
          '${DatabaseService.colLastSynced} IS NULL AND ${DatabaseService.colShopId} = ?',
      whereArgs: [currentShopId],
    );
    if (unsyncedHeaders.isEmpty) return;
    for (var headerMap in unsyncedHeaders) {
      try {
        final String txId = headerMap[DatabaseService.colTransactionId];
        final List<Map<String, dynamic>> items = await db.query(
          DatabaseService.tableTransactionItems,
          where:
              '${DatabaseService.colItemTransactionId} = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [txId, currentShopId],
        );
        await _supabase.from('transactions').upsert(headerMap);

        if (items.isNotEmpty) {
          await _supabase.from('transaction_items').upsert(items);
        }
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await db.update(
          DatabaseService.tableTransactions,
          {DatabaseService.colLastSynced: nowIso},
          where:
              '${DatabaseService.colTransactionId} = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [txId, currentShopId],
        );
        await db.update(
          DatabaseService.tableTransactionItems,
          {DatabaseService.colLastSynced: nowIso},
          where:
              '${DatabaseService.colItemTransactionId} = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [txId, currentShopId],
        );
      } catch (e) {
        debugPrint(
          "Error syncing transaction ${headerMap[DatabaseService.colTransactionId]}: $e",
        );
      }
    }
  }

  Future<void> syncEmployees() async {
    final db = await _dbService.database;

    // 1. Get unsynced employees
    final List<Map<String, dynamic>> unsynced = await db.query(
      DatabaseService.tableEmployee,
      where:
          '${DatabaseService.colLastSynced} IS NULL AND ${DatabaseService.colShopId} = ?',
      whereArgs: [currentShopId],
    );

    if (unsynced.isEmpty) return;

    for (var empMap in unsynced) {
      try {
        // 2. Upload to Supabase
        await _supabase.from('employee').upsert(empMap);

        // 3. Mark as synced locally
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await db.update(
          DatabaseService.tableEmployee,
          {DatabaseService.colLastSynced: nowIso},
          where:
              '${DatabaseService.colEmployeeId} = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [empMap[DatabaseService.colEmployeeId], currentShopId],
        );
      } catch (e) {
        debugPrint("Error syncing employee: $e");
      }
    }
  }

  Future<void> syncTillbalance() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> unsyncedTill = await db.query(
      DatabaseService.tableTillBalance,
      where:
          '${DatabaseService.colLastSynced} IS NULL AND ${DatabaseService.colShopId} = ?',
      whereArgs: [currentShopId],
    );

    if (unsyncedTill.isEmpty) return;
    for (var tillMap in unsyncedTill) {
      try {
        await _supabase.from('till_balance').upsert(tillMap);
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await db.update(
          DatabaseService.tableTillBalance,
          {DatabaseService.colLastSynced: nowIso},
          where:
              '${DatabaseService.colTillBalanceId} = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [tillMap[DatabaseService.colTillBalanceId], currentShopId],
        );
      } catch (e) {
        debugPrint("Error syncing till_balance: $e");
      }
    }
  }

  Future<void> syncProducts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> unsyncedProducts = await db.query(
      DatabaseService.tableProducts,
      where:
          '${DatabaseService.colLastSynced} IS NULL AND ${DatabaseService.colShopId} = ?',
      whereArgs: [currentShopId],
    );

    if (unsyncedProducts.isEmpty) return;
    for (var products in unsyncedProducts) {
      try {
        await _supabase.from('products').upsert(products);
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await db.update(
          DatabaseService.tableProducts,
          {DatabaseService.colLastSynced: nowIso},
          where:
              '${DatabaseService.colProductId} = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [products[DatabaseService.colProductId], currentShopId],
        );
      } catch (e) {
        debugPrint("Error syncing products: $e");
      }
    }
  }

  Future<void> syncCuts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> unsyncedCuts = await db.query(
      DatabaseService.tableCuts,
      where:
          '${DatabaseService.colLastSynced} IS NULL AND ${DatabaseService.colShopId} = ?',
      whereArgs: [currentShopId],
    );

    if (unsyncedCuts.isEmpty) return;
    for (var cuts in unsyncedCuts) {
      try {
        await _supabase.from('cuts').upsert(cuts);
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await db.update(
          DatabaseService.tableCuts,
          {DatabaseService.colLastSynced: nowIso},
          where:
              '${DatabaseService.colCutId} = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [cuts[DatabaseService.colCutId], currentShopId],
        );
      } catch (e) {
        debugPrint("Error syncing Cuts: $e");
      }
    }
  }

  Future<void> syncTimeLogs() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> unsyncedTimelog = await db.query(
      DatabaseService.tableTime,
      where:
          '${DatabaseService.colLastSynced} IS NULL AND ${DatabaseService.colShopId} = ?',
      whereArgs: [currentShopId],
    );

    if (unsyncedTimelog.isEmpty) return;
    for (var time in unsyncedTimelog) {
      try {
        await _supabase.from('time_logs').upsert(time);
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await db.update(
          DatabaseService.tableTime,
          {DatabaseService.colLastSynced: nowIso},
          where:
              '${DatabaseService.colLogId} = ? AND ${DatabaseService.colShopId} = ?',
          whereArgs: [time[DatabaseService.colLogId], currentShopId],
        );
      } catch (e) {
        debugPrint("Error syncing clock logs: $e");
      }
    }
  }

  Future<bool> isOnline() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<bool> syncAll() async {
    if (!await isOnline()) return false;

    try {
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
    }
  }

  void monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        debugPrint("Connection restored: Triggering auto-sync...");
        syncAll();
      }
    });
  }
}
