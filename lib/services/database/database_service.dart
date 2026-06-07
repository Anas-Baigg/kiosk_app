import 'package:intl/intl.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;
  String get currentShopId => AppState.requireShopId();

  static final DatabaseService instance = DatabaseService._constructor();
  static const _dbName = 'barber_db.db';
  static const _dbVersion = 2;
  // Cloud
  static const colShopId = "shop_id";
  static const colLastSynced = "last_synced_at";
  static const colCreatedAt = 'created_at';
  // Employee
  static const tableEmployee = 'employee';
  static const colEmployeeId = 'id';
  static const colName = 'name';
  static const colPasscode = 'passcode';
  static const colIsActive = 'isActive';
  // Cuts
  static const tableCuts = 'cuts';
  static const colCutId = 'id';
  static const colCut = 'cutname';
  static const colPrice = 'price';
  // Products
  static const tableProducts = 'products';
  static const colProductId = 'id';
  static const colProduct = 'productName';
  // Time Logs
  static const tableTime = 'time_logs';
  static const colLogId = 'id';
  static const logEmp = 'employee_id';
  static const clockin = 'clock_in_time';
  static const clockout = 'clock_out_time';
  // Transactions
  static const tableTransactions = 'transactions';
  static const colTransactionId = 'id';
  static const colTransactionEmpId = 'employee_id';
  static const colBaseTotal = 'base_total';
  static const colTip = 'tip';
  static const colDiscount = 'discount';
  static const colFinalTotal = 'final_total';
  static const colPaymentMethod = 'payment_method';
  static const tableTransactionItems = 'transaction_items';
  static const colTransactionItemId = 'id';
  static const colItemTransactionId = 'transaction_id';
  static const colItemType = 'item_type';
  static const colItemName = 'item_name';
  static const colQuantity = 'quantity';
  static const colItemPrice = 'unit_price';
  // Till Balance
  static const tableTillBalance = 'till_balance';
  static const colTillBalanceId = 'id';
  static const colBalanceAmount = 'balance_amount';
  static const colTillDate = 'balance_date';

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databaseDir = join(databaseDirPath, _dbName);
    final database = await openDatabase(
      databaseDir,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableEmployee (
          $colEmployeeId TEXT PRIMARY KEY,
          $colShopId TEXT,
          $colName TEXT NOT NULL,
          $colPasscode INTEGER NOT NULL UNIQUE,
          $colIsActive INTEGER NOT NULL DEFAULT 1,
          $colCreatedAt TEXT NOT NULL,
          $colLastSynced TEXT
          )
          ''');
        await db.execute('''
          CREATE TABLE $tableCuts (
          $colCutId TEXT PRIMARY KEY,
          $colCut TEXT NOT NULL,
          $colPrice REAL NOT NULL,
          $colIsActive INTEGER NOT NULL DEFAULT 1,
          $colShopId TEXT,
          $colCreatedAt TEXT NOT NULL,
          $colLastSynced TEXT
          )
          ''');
        await db.execute('''
          CREATE TABLE $tableProducts (
          $colProductId TEXT PRIMARY KEY,
          $colProduct TEXT NOT NULL,
          $colPrice REAL NOT NULL,
          $colIsActive INTEGER NOT NULL DEFAULT 1,
          $colShopId TEXT,
          $colCreatedAt TEXT NOT NULL,
          $colLastSynced TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableTime(
          $colLogId TEXT PRIMARY KEY,
          $logEmp TEXT NOT NULL,
          $clockin TEXT NOT NULL,
          $clockout TEXT,
          $colShopId TEXT,
          $colLastSynced TEXT,
          FOREIGN KEY ($logEmp) REFERENCES $tableEmployee($colEmployeeId)
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableTransactions (
            $colTransactionId TEXT PRIMARY KEY,
            $colTransactionEmpId TEXT NOT NULL,
            $colBaseTotal REAL NOT NULL,
            $colTip REAL NOT NULL DEFAULT 0,
            $colDiscount REAL NOT NULL DEFAULT 0,
            $colFinalTotal REAL NOT NULL,
            $colPaymentMethod TEXT NOT NULL,
            $colCreatedAt TEXT NOT NULL,
            $colShopId TEXT,
            $colLastSynced TEXT,
            FOREIGN KEY ($colTransactionEmpId) REFERENCES $tableEmployee($colEmployeeId)
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableTransactionItems (
            $colTransactionItemId TEXT PRIMARY KEY,
            $colItemTransactionId TEXT NOT NULL,
            $colItemType TEXT NOT NULL,
            $colItemName TEXT NOT NULL,
            $colItemPrice REAL NOT NULL,
            $colQuantity INTEGER NOT NULL,
            $colShopId TEXT,
            $colLastSynced TEXT,
            FOREIGN KEY ($colItemTransactionId) REFERENCES $tableTransactions($colTransactionId)
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableTillBalance (
            $colTillBalanceId TEXT PRIMARY KEY,
            $colBalanceAmount REAL NOT NULL DEFAULT 0.0,
            $colTillDate TEXT NOT NULL,
            $colShopId TEXT,
            $colLastSynced TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_time_open ON $tableTime($logEmp, $clockout)',
        );
        await db.execute('''
          CREATE UNIQUE INDEX IF NOT EXISTS uq_cuts_active_name_per_shop
          ON $tableCuts($colShopId, $colCut)
          WHERE $colIsActive = 1
        ''');
        await db.execute('''
          CREATE UNIQUE INDEX IF NOT EXISTS uq_products_active_name_per_shop
          ON $tableProducts($colShopId, $colProduct)
          WHERE $colIsActive = 1
        ''');
        await _createPerformanceIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createPerformanceIndexes(db);
      },
    );
    return database;
  }

  static Future<void> _createPerformanceIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_employee_shop ON $tableEmployee($colShopId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_time_shop ON $tableTime($colShopId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_time_clockin ON $tableTime($clockin)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_shop ON $tableTransactions($colShopId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_createdat ON $tableTransactions($colCreatedAt)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_txitems_txid ON $tableTransactionItems($colItemTransactionId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_txitems_shop ON $tableTransactionItems($colShopId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tillbalance_shop ON $tableTillBalance($colShopId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tillbalance_date ON $tableTillBalance($colTillDate)');
  }

  // Generic CRUD — used by management_list_page for any entity table
  Future<int> addEPC({
    required String table,
    required Map<String, dynamic> data,
    ConflictAlgorithm conflict = ConflictAlgorithm.rollback,
  }) async {
    final db = await database;
    try {
      return await db.insert(table, data, conflictAlgorithm: conflict);
    } catch (e) {
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        throw Exception("This entry already exists.");
      }
      throw Exception("Database error: ${e.toString()}");
    }
  }

  Future<List<T>> getEPC<T>({
    required String table,
    required T Function(Map<String, dynamic>) fromMap,
    String? orderBy,
    bool onlyActive = false,
  }) async {
    final db = await database;
    final rows = await db.query(
      table,
      where:
          onlyActive ? '$colShopId = ? AND $colIsActive = 1' : '$colShopId = ?',
      whereArgs: [currentShopId],
      orderBy: orderBy,
    );
    return rows.map((map) => fromMap(map)).toList();
  }

  Future<int> updateEPC({
    required String table,
    required Map<String, dynamic> data,
    ConflictAlgorithm conflict = ConflictAlgorithm.rollback,
    required dynamic id,
  }) async {
    final db = await database;
    return db.update(
      table,
      data,
      where: 'id = ? AND $colShopId = ?',
      whereArgs: [id, currentShopId],
      conflictAlgorithm: conflict,
    );
  }

  Future<int> deactivateEPC({
    required String table,
    required String idColumn,
    required String id,
  }) async {
    final db = await database;
    return db.update(
      table,
      {colIsActive: 0, colLastSynced: null},
      where: '$idColumn = ? AND $colShopId = ?',
      whereArgs: [id, currentShopId],
    );
  }

  // Multi-table purge — spans all entity tables, lives here as a cross-cutting utility
  Future<void> purgeOldHistory({int keepDays = 30}) async {
    final db = await database;

    final nowLocal = DateTime.now();
    final startOfTodayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final cutoffLocal = startOfTodayLocal.subtract(Duration(days: keepDays));

    final cutoffIsoUtc = cutoffLocal.toUtc().toIso8601String();
    final cutoffDateStr = DateFormat('yyyy-MM-dd').format(cutoffLocal);

    await db.transaction((txn) async {
      await txn.delete(
        tableTransactionItems,
        where: '''
        $colShopId = ?
        AND $colLastSynced IS NOT NULL
        AND $colItemTransactionId IN (
          SELECT $colTransactionId
          FROM $tableTransactions
          WHERE $colShopId = ?
            AND $colCreatedAt < ?
            AND $colLastSynced IS NOT NULL
        )
      ''',
        whereArgs: [currentShopId, currentShopId, cutoffIsoUtc],
      );
      await txn.delete(
        tableTransactions,
        where: '''
        $colShopId = ?
        AND $colCreatedAt < ?
        AND $colLastSynced IS NOT NULL
      ''',
        whereArgs: [currentShopId, cutoffIsoUtc],
      );
      await txn.delete(
        tableTime,
        where: '''
        $colShopId = ?
        AND $clockin < ?
        AND $colLastSynced IS NOT NULL
      ''',
        whereArgs: [currentShopId, cutoffIsoUtc],
      );
      await txn.delete(
        tableTillBalance,
        where: '''
        $colShopId = ?
        AND $colTillDate < ?
        AND $colLastSynced IS NOT NULL
      ''',
        whereArgs: [currentShopId, cutoffDateStr],
      );
    });
  }
}
