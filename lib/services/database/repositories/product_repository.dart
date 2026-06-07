import 'package:kiosk_app/models/products.dart';
import 'package:kiosk_app/services/database/database_service.dart';

class ProductRepository {
  final DatabaseService _db;
  ProductRepository(this._db);

  Future<List<Product>> getAll() => _db.getEPC<Product>(
        table: DatabaseService.tableProducts,
        fromMap: Product.fromMap,
        orderBy: '${DatabaseService.colProduct} COLLATE NOCASE',
        onlyActive: true,
      );

  Future<int> add(Product product) =>
      _db.addEPC(table: DatabaseService.tableProducts, data: product.toMap());

  Future<int> update(Product product) => _db.updateEPC(
        table: DatabaseService.tableProducts,
        data: product.toMap(),
        id: product.id,
      );

  Future<int> deactivate(String id) => _db.deactivateEPC(
        table: DatabaseService.tableProducts,
        idColumn: DatabaseService.colProductId,
        id: id,
      );
}
