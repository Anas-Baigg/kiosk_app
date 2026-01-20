// ignore_for_file: file_names

import 'package:kiosk_app/services/database_service.dart';

class TransactionItem {
  final String? id;
  final String? transactionId;

  final String itemType;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final String? shopId;
  final DateTime? lastSyncedAt;

  TransactionItem({
    this.id,
    this.transactionId,
    required this.itemType,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    this.shopId,
    this.lastSyncedAt,
  });

  //For saving to the database
  Map<String, dynamic> toMap() {
    return {
      DatabaseService.colTransactionItemId: id,
      DatabaseService.colItemTransactionId: transactionId,
      DatabaseService.colItemType: itemType,
      DatabaseService.colItemName: itemName,
      DatabaseService.colItemPrice: unitPrice,
      DatabaseService.colQuantity: quantity,
      DatabaseService.colLastSynced: lastSyncedAt?.toUtc().toIso8601String(),
      DatabaseService.colShopId: shopId,
    };
  }

  // For retrieving from the database)
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map[DatabaseService.colTransactionItemId] as String,
      shopId: map[DatabaseService.colShopId] as String?,
      transactionId: map[DatabaseService.colItemTransactionId] as String,
      itemType: map[DatabaseService.colItemType] as String,
      itemName: map[DatabaseService.colItemName] as String,
      unitPrice: (map[DatabaseService.colItemPrice] as num).toDouble(),
      quantity: map[DatabaseService.colQuantity] as int,
      lastSyncedAt: map[DatabaseService.colLastSynced] != null
          ? DateTime.parse(
              map[DatabaseService.colLastSynced] as String,
            ).toLocal()
          : null,
    );
  }
}
