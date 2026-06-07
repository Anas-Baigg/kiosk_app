import 'package:kiosk_app/models/cuts.dart';
import 'package:kiosk_app/services/database/database_service.dart';

class CutsRepository {
  final DatabaseService _db;
  CutsRepository(this._db);

  Future<List<Cuts>> getAll() => _db.getEPC<Cuts>(
        table: DatabaseService.tableCuts,
        fromMap: Cuts.fromMap,
        orderBy: '${DatabaseService.colCut} COLLATE NOCASE',
        onlyActive: true,
      );

  Future<int> add(Cuts cut) =>
      _db.addEPC(table: DatabaseService.tableCuts, data: cut.toMap());

  Future<int> update(Cuts cut) => _db.updateEPC(
        table: DatabaseService.tableCuts,
        data: cut.toMap(),
        id: cut.id,
      );

  Future<int> deactivate(String id) => _db.deactivateEPC(
        table: DatabaseService.tableCuts,
        idColumn: DatabaseService.colCutId,
        id: id,
      );
}
