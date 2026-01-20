import 'package:flutter/material.dart';
import 'package:kiosk_app/components/cuts.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/cuts_validators.dart';
import 'package:kiosk_app/services/database_service.dart';
import 'package:kiosk_app/services/download_service.dart';
import 'package:kiosk_app/ui/management_list_page.dart';
import 'package:uuid/uuid.dart';

class AddCuts extends StatelessWidget {
  const AddCuts({super.key});
  String get currentShopId => AppState.requireShopId();

  @override
  Widget build(BuildContext context) {
    // 1. Define the configuration for "Cuts"
    final cutsConfig = ManagementPageConfig<Cuts>(
      pageTitle: "Add Cuts",
      listTitle: "Cuttings",
      itemName: "Cut",
      field1Label: "Cutting Name",
      field2Label: "Price",
      field2KeyboardType: const TextInputType.numberWithOptions(decimal: true),
      listIcon: Icons.cut_sharp,
      tableName: DatabaseService.tableCuts,
      orderByColumn: DatabaseService.colCut,
      idColumn: DatabaseService.colCutId,

      // Data Handlers
      fromMap: (map) => Cuts.fromMap(map),
      toMap: (cut) => cut.toMap(),
      getId: (cut) => cut.id,
      getName: (cut) => cut.cutname,
      getValueString: (cut) => cut.price.toString(),
      getSubtitle: (cut) => "Price: ${cut.price?.toStringAsFixed(2)}",

      // Validation
      validateField1: CutsValidators.validateCutName,
      validateField2: CutsValidators.validatePrice,
      onRefresh: () => PullService().downloadCuts(),
      // Creation
      createItem: (name, price) {
        final uuid = const Uuid();
        return Cuts(
          id: uuid.v4(),
          cutname: name,
          price: double.tryParse(price),
          createdAt: DateTime.now(),
          shopId: currentShopId,
        );
      },
      updateItem: (originalItem, name, price) => Cuts(
        id: originalItem.id,
        cutname: name,
        price: double.tryParse(price),
        createdAt: originalItem.createdAt,
        shopId: originalItem.shopId,
        isActive: originalItem.isActive,
      ),
    );

    // 2. Return the generic page with the config
    return GenericManagementPage<Cuts>(config: cutsConfig);
  }
}
