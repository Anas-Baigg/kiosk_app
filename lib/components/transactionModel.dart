// ignore_for_file: file_names

import 'package:kiosk_app/services/database_service.dart';

class TransactionHeader {
  final String? id;
  final String employeeId;
  final String? employeeName;
  final double baseTotal;
  final double tip;
  final double discount;
  final double finalTotal;
  final String paymentMethod;
  final DateTime timestamp;
  final String? shopId;
  final DateTime? lastSyncedAt;

  TransactionHeader({
    this.id,
    required this.employeeId,
    this.employeeName,
    this.shopId,
    this.lastSyncedAt,
    required this.baseTotal,
    required this.tip,
    required this.discount,
    required this.finalTotal,
    required this.paymentMethod,
    required this.timestamp,
  });

  // For saving to the database
  Map<String, dynamic> toMap() {
    return {
      DatabaseService.colTransactionId: id,
      DatabaseService.colTransactionEmpId: employeeId,
      DatabaseService.colBaseTotal: baseTotal,
      DatabaseService.colTip: tip,
      DatabaseService.colDiscount: discount,
      DatabaseService.colFinalTotal: finalTotal,
      DatabaseService.colPaymentMethod: paymentMethod,
      DatabaseService.colCreatedAt: timestamp.toUtc().toIso8601String(),
      DatabaseService.colLastSynced: lastSyncedAt?.toUtc().toIso8601String(),
      DatabaseService.colShopId: shopId,
    };
  }

  // For retrieving from the database
  factory TransactionHeader.fromMap(Map<String, dynamic> map) {
    return TransactionHeader(
      id: map[DatabaseService.colTransactionId] as String,
      shopId: map[DatabaseService.colShopId] as String?,
      employeeId: map[DatabaseService.colTransactionEmpId] as String,
      employeeName: map['employeeName'] ?? '',
      baseTotal: (map[DatabaseService.colBaseTotal] as num).toDouble(),
      tip: (map[DatabaseService.colTip] as num).toDouble(),
      discount: (map[DatabaseService.colDiscount] as num).toDouble(),
      finalTotal: (map[DatabaseService.colFinalTotal] as num).toDouble(),
      paymentMethod: map[DatabaseService.colPaymentMethod] as String,
      timestamp: DateTime.parse(
        map[DatabaseService.colCreatedAt] as String,
      ).toLocal(),
      lastSyncedAt: map[DatabaseService.colLastSynced] != null
          ? DateTime.parse(
              map[DatabaseService.colLastSynced] as String,
            ).toLocal()
          : null,
    );
  }
}
