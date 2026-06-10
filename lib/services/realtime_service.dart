import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../screens/app_state.dart';
import '../utils/logger.dart';
import 'database/database_service.dart';

class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  RealtimeChannel? _channel;
  final _supabase = Supabase.instance.client;

  static const _tables = ['employee', 'cuts', 'products', 'till_balance'];

  Future<void> subscribe() async {
    final shopId = AppState.shopIdOrNull;
    if (shopId == null) return;

    await unsubscribe();

    AppLogger.info('Realtime: subscribing for shop $shopId');

    var channel = _supabase.channel('reference_data_$shopId');

    for (final table in _tables) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'shop_id',
          value: shopId,
        ),
        callback: (payload) => _handleChange(table, payload),
      );
    }

    _channel = channel.subscribe((status, [error]) {
      AppLogger.info('Realtime status: $status');
      if (error != null) AppLogger.error('Realtime error', error);
    });
  }

  Future<void> unsubscribe() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
      AppLogger.info('Realtime: unsubscribed');
    }
  }

  Future<void> _handleChange(
    String table,
    PostgresChangePayload payload,
  ) async {
    try {
      final db = DatabaseService.instance;
      final shopId = AppState.shopIdOrNull;
      if (shopId == null) return;

      AppLogger.sync('Realtime: ${payload.eventType} on $table');

      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          final record = Map<String, dynamic>.from(payload.newRecord);
          record[DatabaseService.colLastSynced] = DateTime.now()
              .toUtc()
              .toIso8601String();
          // Normalize boolean isActive to integer for SQLite
          if (record.containsKey(DatabaseService.colIsActive)) {
            record[DatabaseService.colIsActive] =
                (record[DatabaseService.colIsActive] == true) ? 1 : 0;
          }
          final database = await db.database;
          await database.insert(
            table,
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          break;

        case PostgresChangeEvent.delete:
          // Safety net — dashboard uses soft-delete (isActive=false) for
          // employee/cuts/products so this branch is rarely hit.
          final id = payload.oldRecord['id'];
          if (id != null) {
            final database = await db.database;
            await database.delete(
              table,
              where: 'id = ? AND shop_id = ?',
              whereArgs: [id, shopId],
            );
          }
          break;

        default:
          break;
      }

      _onReferenceDataChanged?.call(table);
    } catch (e, stack) {
      AppLogger.error('Realtime: failed to handle $table change', e, stack);
    }
  }

  void Function(String table)? _onReferenceDataChanged;

  void setOnChangeCallback(void Function(String table) callback) {
    _onReferenceDataChanged = callback;
  }

  void clearOnChangeCallback() {
    _onReferenceDataChanged = null;
  }
}
