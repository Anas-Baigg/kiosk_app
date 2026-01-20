import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class PullService {
  final _supabase = Supabase.instance.client;
  final _dbService = DatabaseService.instance;

  String get currentShopId => AppState.requireShopId();

  // ---------------- Public API ----------------

  Future<void> fullDownloadFromCloud({int historyDays = 60}) async {
    debugPrint("Starting Full Sync: Pruning then Downloading...");

    // 1. CLEANUP FIRST: Remove old local data to prevent FK conflicts and clutter
    await _dbService.purgeOldHistory(keepDays: historyDays);

    // 2. REFERENCE DATA: Sync employees, products, and cuts
    await downloadEmployees();
    await downloadProducts();
    await downloadCuts();

    // 3. DOWNLOAD FRESH DATA: Pull the window of history you want to keep
    await downloadRecentHistory(historyDays: historyDays);

    debugPrint("Full Sync complete.");
  }

  // 1) Employees (Supabase: employee)
  Future<void> downloadEmployees() async {
    await _downloadReferenceTable(
      remoteTable: 'employee',
      localTable: DatabaseService.tableEmployee,
      normalizeIsActive: true,
    );
  }

  // 2) Products (Supabase: products)
  Future<void> downloadProducts() async {
    await _downloadReferenceTable(
      remoteTable: 'products',
      localTable: DatabaseService.tableProducts,
      normalizeIsActive: true,
    );
  }

  // 3) Cuts (Supabase: cuts)
  Future<void> downloadCuts() async {
    await _downloadReferenceTable(
      remoteTable: 'cuts',
      localTable: DatabaseService.tableCuts,
      normalizeIsActive: true,
    );
  }

  // History: transactions + items + time_logs (last N days)
  Future<void> downloadRecentHistory({int historyDays = 60}) async {
    final db = await _dbService.database;
    final cutoffIso = DateTime.now()
        .toUtc()
        .subtract(Duration(days: historyDays))
        .toIso8601String();

    try {
      // ---------------- A) Transactions (headers) ----------------
      final List<dynamic> txData = await _supabase
          .from('transactions')
          .select()
          .eq('shop_id', currentShopId)
          .gte('created_at', cutoffIso);

      final txList = txData.map((e) => Map<String, dynamic>.from(e)).toList();

      // Insert transactions in ONE sqlite transaction
      await db.transaction((txn) async {
        for (final tx in txList) {
          // enforce correct shop_id locally
          tx['shop_id'] = currentShopId;

          await txn.insert(
            DatabaseService.tableTransactions,
            tx,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      // ---------------- B) Transaction Items (batched, no N+1) ----------------
      if (txList.isNotEmpty) {
        final txIds = txList.map((m) => m['id']).whereType<String>().toList();

        final allItems = <Map<String, dynamic>>[];

        // Chunk IDs so IN() stays reasonable
        for (final chunk in _chunks(txIds, 200)) {
          final List<dynamic> itemData = await _supabase
              .from('transaction_items')
              .select()
              // If your transaction_items also has shop_id, keep this filter.
              // If it doesn't, remove it.
              .eq('shop_id', currentShopId)
              .inFilter('transaction_id', chunk);

          allItems.addAll(itemData.map((e) => Map<String, dynamic>.from(e)));
        }

        await db.transaction((txn) async {
          for (final item in allItems) {
            // enforce correct shop_id locally if that column exists locally
            item['shop_id'] = currentShopId;

            await txn.insert(
              DatabaseService.tableTransactionItems,
              item,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      }

      // ---------------- C) Time Logs ----------------
      final List<dynamic> logData = await _supabase
          .from('time_logs')
          .select()
          .eq('shop_id', currentShopId)
          .gte('clock_in_time', cutoffIso);

      final logList = logData.map((e) => Map<String, dynamic>.from(e)).toList();

      await db.transaction((txn) async {
        for (final log in logList) {
          log['shop_id'] = currentShopId;
          await txn.insert(
            DatabaseService.tableTime,
            log,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      // ---------------- D) Till Balance ----------------
      final List<dynamic> tillData = await _supabase
          .from('till_balance')
          .select()
          .eq('shop_id', currentShopId)
          .gte('balance_date', cutoffIso);

      final tillList = tillData
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      await db.transaction((txn) async {
        for (final row in tillList) {
          row['shop_id'] = currentShopId;
          await txn.insert(
            DatabaseService.tableTillBalance,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      // keep your existing style of error reporting
      debugPrint("Error downloading history: $e");
    }
  }

  // ---------------- Generic helpers ----------------

  Future<void> _downloadReferenceTable({
    required String remoteTable,
    required String localTable,
    bool normalizeIsActive = false,
  }) async {
    final db = await _dbService.database;

    try {
      final List<dynamic> data = await _supabase
          .from(remoteTable)
          .select()
          .eq('shop_id', currentShopId);

      final rows = data.map((e) => Map<String, dynamic>.from(e)).toList();

      await db.transaction((txn) async {
        for (final row in rows) {
          // enforce correct shop_id locally
          row['shop_id'] = currentShopId;

          if (normalizeIsActive &&
              row.containsKey(DatabaseService.colIsActive)) {
            row[DatabaseService.colIsActive] =
                (row[DatabaseService.colIsActive] == true) ? 1 : 0;
          }

          await txn.insert(
            localTable,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      debugPrint("Error downloading $remoteTable: $e");
    }
  }

  Iterable<List<T>> _chunks<T>(List<T> input, int size) sync* {
    for (var i = 0; i < input.length; i += size) {
      yield input.sublist(i, i + size > input.length ? input.length : i + size);
    }
  }
}
