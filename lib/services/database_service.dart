import 'package:intl/intl.dart';
import 'package:kiosk_app/components/till_balance.dart';
import 'package:kiosk_app/components/time_log_entry.dart';
import 'package:kiosk_app/components/timelog.dart';
import 'package:kiosk_app/components/transaction_item.dart';
import 'package:kiosk_app/components/transactionModel.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static Database? _db;
  String get currentShopId => AppState.requireShopId();

  // Use currentShop in your INSERT map
  // Good use of the Singleton pattern here!
  static final DatabaseService instance = DatabaseService._constructor();
  static const _dbName = 'barber_db.db';
  static const _dbVersion = 1;
  // Cloud Things
  static const colShopId = "shop_id";
  static const colLastSynced = "last_synced_at";
  static const colCreatedAt = 'created_at';
  // Employee Table
  static const tableEmployee = 'employee';
  static const colEmployeeId = 'id';
  static const colName = 'name';
  static const colPasscode = 'passcode';
  static const colIsActive = 'isActive';
  // Cuts Table
  static const tableCuts = 'cuts';
  static const colCutId = 'id';
  static const colCut = 'cutname';
  static const colPrice = 'price';

  // Products Table
  static const tableProducts = 'products';
  static const colProductId = 'id';
  static const colProduct = 'productName';

  // Time Logs Table
  static const tableTime = 'time_logs';
  static const colLogId = 'id';
  static const logEmp = 'employee_id';
  static const clockin = 'clock_in_time';
  static const clockout = 'clock_out_time';

  // --- NEW: Transactions Table ---
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
      },
    );
    return database;
  }

  // Getters------------------------------------------------
  // Function for adding Employee, cuts, and products
  Future<int> addEPC({
    required String table,
    required Map<String, dynamic> data,
    ConflictAlgorithm conflict = ConflictAlgorithm.rollback,
  }) async {
    final db = await database;
    try {
      return await db.insert(table, data, conflictAlgorithm: conflict);
    } catch (e) {
      // UNIQUE constraint failed
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        throw Exception("This entry already exists.");
      }

      // Other errors
      throw Exception("Database error: ${e.toString()}");
    }
  }

  // Function for getting Employee, cuts, and products
  Future<List<T>> getEPC<T>({
    required String table,
    required T Function(Map<String, dynamic>) fromMap,
    String? orderBy,
    bool onlyActive = false,
  }) async {
    final db = await database;

    final rows = await db.query(
      table,
      where: onlyActive
          ? '$colShopId = ? AND $colIsActive = 1'
          : '$colShopId = ?',
      whereArgs: [currentShopId],
      orderBy: orderBy,
    );

    return rows.map((map) => fromMap(map)).toList();
  }

  // Function for updatings Employee, cuts, and products
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

  // delete in DatabaseService
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

  //------------------------Clock__Logs---------------------------//

  // Gets the most recent open time log
  Future<Map<String, dynamic>?> _getLatestOpenLog(dynamic employeeId) async {
    final db = await database;
    final res = await db.query(
      tableTime,
      where: '$logEmp = ? AND $clockout IS NULL AND $colShopId = ?',
      whereArgs: [employeeId, currentShopId],

      orderBy: '$clockin DESC',
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  // 1. EMPLOYEE PASSCODE VERIFICATION
  //
  Future<String?> getEmployeeIdByPasscode(String passcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableEmployee,
      columns: [colEmployeeId],
      where: '$colPasscode = ? AND $colIsActive = 1 AND $colShopId = ?',
      whereArgs: [passcode, currentShopId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first[colEmployeeId] as String;
    }
    return null;
  }

  // 2. CLOCK IN REGISTRATION
  Future<int> clockIn(dynamic employeeId) async {
    final db = await database;

    final latestOpenLog = await _getLatestOpenLog(employeeId);

    // FIX 3: Use local time for day-boundary checks (since you are "daytime only")
    final nowLocal = DateTime.now(); // Local time for comparison

    final uuid = const Uuid();

    if (latestOpenLog == null) {
      // No open log found, perform standard clock-in
      return db.insert(
        tableTime,
        TimeLog(
          id: uuid.v4(),
          employeeId: employeeId,
          clockIn: nowLocal,
          clockOut: null,
          shopId: currentShopId,
        ).toMap(),
      );
    }

    // --- A LOG EXISTS ---
    // An open log was found. We need to check when it's from.
    final clockInString = latestOpenLog[clockin] as String;

    // Parse the stored UTC time, then convert to LOCAL for day comparison
    final clockInTimeLocal = DateTime.parse(clockInString).toLocal();

    // 2. Check if the open log is from *today* (in local time)
    final bool isFromToday =
        clockInTimeLocal.year == nowLocal.year &&
        clockInTimeLocal.month == nowLocal.month &&
        clockInTimeLocal.day == nowLocal.day;

    if (isFromToday) {
      return -1; // "Already clocked in" (No need to clock in twice in one local day)
    } else {
      // Forgot clock-out on a previous day. Auto-clock out at 23:59:59 of the previous day (local).
      final endOfOldDayLocal = DateTime(
        clockInTimeLocal.year,
        clockInTimeLocal.month,
        clockInTimeLocal.day,
        23,
        59,
        59,
      );

      // Convert the local midnight cutoff back to UTC for storage
      final autoClockOutIso = endOfOldDayLocal.toUtc().toIso8601String();
      final oldLogId = latestOpenLog[colLogId] as String;

      await db.update(
        tableTime,
        {clockout: autoClockOutIso},
        where: '$colLogId = ?',
        whereArgs: [oldLogId],
      );

      // 4. Now, create the new shift for today
      return db.insert(
        tableTime,
        TimeLog(
          id: uuid.v4(),
          employeeId: employeeId,
          clockIn: nowLocal,
          clockOut: null,
          shopId: currentShopId,
        ).toMap(),
      );
    }
  }

  // 3. CLOCK OUT UPDATE & VALIDATION
  Future<bool> clockOut(dynamic employeeId) async {
    final db = await database;
    final openLog = await _getLatestOpenLog(employeeId);
    if (openLog == null) return false;

    final openId = openLog[colLogId] as String;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final count = await db.update(
      tableTime,
      {clockout: nowIso, colLastSynced: null},
      where: '$colLogId = ?',
      whereArgs: [openId],
    );

    return count > 0;
  }

  // ACTIVE EMPLOYEES
  Future<List<Map<String, dynamic>>> getActiveEmployees() async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT e.$colEmployeeId, e.$colName
      FROM $tableTime t
      JOIN $tableEmployee e ON e.$colEmployeeId = t.$logEmp
      WHERE t.$clockout IS NULL
        AND t.$colShopId = ?
        AND date(t.$clockin, 'utc', 'localtime') = date('now', 'localtime')
      GROUP BY e.$colEmployeeId, e.$colName
      ORDER BY e.$colName COLLATE NOCASE
      ''',
      [currentShopId],
    );
  }

  //----------------------------------Transaction------------------------

  Future<String> saveTransactionObjects(
    TransactionHeader header,
    List<TransactionItem> items,
  ) async {
    final db = await database;
    final uuid = const Uuid();

    // 1. Generate ONE transaction UUID
    final transactionId = uuid.v4();

    // 2. Create a new header with the generated ID
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
      // 3. Insert header
      await txn.insert(
        tableTransactions,
        headerWithId.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. Insert all items
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

        await txn.insert(
          tableTransactionItems,
          itemWithIds.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    // 5. Return the UUID, not an int
    return transactionId;
  }

  Future<List<TransactionHeader>> getTransactionsBetweenDates({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;
    final startOfFromDay = DateTime(from.year, from.month, from.day);
    final startOfDayAfterTo = DateTime(to.year, to.month, to.day + 1);
    final fromMs = startOfFromDay.toUtc().toIso8601String();
    final toMsExclusive = startOfDayAfterTo.toUtc().toIso8601String();
    // 3. Query the database
    final rows = await db.rawQuery(
      '''
    SELECT 
      t.*, 
      e.$colName AS employeeName
    FROM $tableTransactions t
    LEFT JOIN $tableEmployee e
      ON t.$colTransactionEmpId = e.$colEmployeeId
    WHERE t.$colShopId = ?
      AND t.$colCreatedAt >= ? AND t.$colCreatedAt < ?
    ORDER BY t.$colCreatedAt DESC
  ''',
      [currentShopId, fromMs, toMsExclusive],
    );
    // 4. Convert maps -> TransactionHeader objects

    return rows.map((map) => TransactionHeader.fromMap(map)).toList();
  }

  Future<List<TransactionItem>> getItemsForTransaction(
    String transactionId,
  ) async {
    final db = await database;

    // Query rows where the transaction_id matches the given ID
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactionItems,
      where: '$colItemTransactionId = ? AND $colShopId = ?',
      whereArgs: [transactionId, currentShopId],
    );

    // Convert the list of maps into a list of TransactionItem objects
    return List.generate(maps.length, (i) {
      return TransactionItem.fromMap(maps[i]);
    });
  }

  Future<List<TimeLogEntry>> getTimeLogsBetweenDates({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;

    // Use the same "whole day" logic as your transactions:
    final startOfFromDay = DateTime(from.year, from.month, from.day);
    final startOfDayAfterTo = DateTime(to.year, to.month, to.day + 1);

    final fromIso = startOfFromDay.toUtc().toIso8601String();
    final toIsoExclusive = startOfDayAfterTo.toUtc().toIso8601String();

    // We join with employee to get names
    final rows = await db.rawQuery(
      '''
    SELECT 
      t.$colLogId AS log_id,
      t.$logEmp AS employee_id,
      e.$colName AS employee_name,
      t.$clockin AS clock_in,
      t.$clockout AS clock_out
    FROM $tableTime t
    JOIN $tableEmployee e ON e.$colEmployeeId = t.$logEmp
    WHERE t.$colShopId = ?
      AND t.$clockin >= ? AND t.$clockin < ?
    ORDER BY t.$clockin ASC
  ''',
      [currentShopId, fromIso, toIsoExclusive],
    );

    return rows.map((row) => TimeLogEntry.fromMap(row)).toList();
  }

  //-----------------------------
  Future<int> insertTillBalance(TillBalance balance) async {
    final db = await database;
    return await db.insert(
      tableTillBalance,
      balance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TillBalance?> getTillBalanceByDate(DateTime date) async {
    final db = await database;
    final d = DateFormat('yyyy-MM-dd').format(date);
    final rows = await db.query(
      tableTillBalance,
      where: '$colTillDate = ? AND $colShopId = ?',
      whereArgs: [d, currentShopId],
    );

    if (rows.isNotEmpty) {
      return TillBalance.fromMap(rows.first);
    }
    return null;
  }

  Future<List<TillBalance>> getBalanceBetweenDates({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;

    final startOfFromDay = DateTime(from.year, from.month, from.day);
    final startOfDayAfterTo = DateTime(to.year, to.month, to.day + 1);

    final fromStr = DateFormat('yyyy-MM-dd').format(startOfFromDay);
    final toStrExclusive = DateFormat('yyyy-MM-dd').format(startOfDayAfterTo);

    final rows = await db.query(
      tableTillBalance,
      where: '$colShopId = ? AND $colTillDate >= ? AND $colTillDate < ?',
      whereArgs: [currentShopId, fromStr, toStrExclusive],
    );
    return rows.map((row) => TillBalance.fromMap(row)).toList();
  }

  // -----------------------------
  // Local retention / purge
  Future<void> purgeOldHistory({int keepDays = 60}) async {
    final db = await database;

    // Use "start of day" so retention behaves like "keep last N calendar days"
    final nowLocal = DateTime.now();
    final startOfTodayLocal = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );
    final cutoffLocal = startOfTodayLocal.subtract(Duration(days: keepDays));

    // For tables storing UTC ISO timestamps (created_at, clock_in_time)
    final cutoffIsoUtc = cutoffLocal.toUtc().toIso8601String();

    // For till_balance which stores yyyy-MM-dd as TEXT
    final cutoffDateStr = DateFormat('yyyy-MM-dd').format(cutoffLocal);

    await db.transaction((txn) async {
      // 1) Delete transaction_items that belong to old transactions
      // (Delete children first to satisfy FK constraints)
      await txn.delete(
        tableTransactionItems,
        where:
            '''
        $colShopId = ?
        AND $colItemTransactionId IN (
          SELECT $colTransactionId
          FROM $tableTransactions
          WHERE $colShopId = ? AND $colCreatedAt < ?
        )
      ''',
        whereArgs: [currentShopId, currentShopId, cutoffIsoUtc],
      );

      // 2) Delete old transactions (headers)
      await txn.delete(
        tableTransactions,
        where: '$colShopId = ? AND $colCreatedAt < ?',
        whereArgs: [currentShopId, cutoffIsoUtc],
      );

      // 3) Delete old time logs
      await txn.delete(
        tableTime,
        where: '$colShopId = ? AND $clockin < ?',
        whereArgs: [currentShopId, cutoffIsoUtc],
      );

      // 4) Delete old till balance rows (yyyy-MM-dd TEXT comparison works)
      await txn.delete(
        tableTillBalance,
        where: '$colShopId = ? AND $colTillDate < ?',
        whereArgs: [currentShopId, cutoffDateStr],
      );
    });
  }
}
