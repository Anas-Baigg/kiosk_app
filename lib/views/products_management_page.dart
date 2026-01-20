import 'package:flutter/material.dart';
import 'package:kiosk_app/components/products.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/download_service.dart';
import 'package:kiosk_app/services/products_validators.dart';
import 'package:kiosk_app/services/database_service.dart';
import 'package:kiosk_app/ui/management_list_page.dart';
import 'package:uuid/uuid.dart';

class AddProducts extends StatelessWidget {
  const AddProducts({super.key});
  String get currentShopId => AppState.requireShopId();

  @override
  Widget build(BuildContext context) {
    // 1. Define the configuration for "Products"
    final productsConfig = ManagementPageConfig<Product>(
      pageTitle: "Add products",
      listTitle: "Products",
      itemName: "Product",
      field1Label: "Product Name",
      field2Label: "Product Price",
      field2KeyboardType: const TextInputType.numberWithOptions(decimal: true),
      listIcon: Icons.shopping_basket,
      tableName: DatabaseService.tableProducts,
      orderByColumn: DatabaseService.colProduct,
      idColumn: DatabaseService.colProductId,

      // Data Handlers
      fromMap: (map) => Product.fromMap(map),
      toMap: (prod) => prod.toMap(),
      getId: (prod) => prod.id,
      getName: (prod) => prod.productName,
      getValueString: (prod) => prod.price.toString(),
      getSubtitle: (prod) => "Price: ${prod.price?.toStringAsFixed(2)}",

      // Validation
      validateField1: ProductValidators.validateProductName,
      validateField2: ProductValidators.validatePrice,
      onRefresh: () => PullService().downloadProducts(),
      // Creation
      createItem: (name, price) {
        final uuid = const Uuid();
        return Product(
          id: uuid.v4(),
          productName: name,
          price: double.tryParse(price),
          createdAt: DateTime.now(),
          shopId: currentShopId,
        );
      },
      updateItem: (originalItem, name, price) => Product(
        id: originalItem.id,
        productName: name,
        price: double.tryParse(price),
        createdAt: originalItem.createdAt,
        shopId: originalItem.shopId,
        isActive: originalItem.isActive,
      ),
    );

    // 2. Return the generic page with the config
    return GenericManagementPage<Product>(config: productsConfig);
  }
}
