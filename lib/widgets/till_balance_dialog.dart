import 'package:flutter/material.dart';
import 'package:kiosk_app/models/till_balance.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/database/database_service.dart';
import 'package:kiosk_app/services/database/repositories/till_balance_repository.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:uuid/uuid.dart';

class TillBalanceDialog {
  static Future<bool> checkAndShow(BuildContext context) async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final repo = TillBalanceRepository(DatabaseService.instance);

    final existing = await repo.getTillBalanceByDate(todayMidnight);

    if (existing != null) return true;

    final result = await _showOpeningDialog(context, todayMidnight);

    return result ?? false;
  }

  static Future<bool?> _showOpeningDialog(
    BuildContext context,
    DateTime today,
  ) async {
    final TextEditingController controller = TextEditingController();

    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          scrollable: true,
          title: const Text("Enter Opening Till Balance"),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Opening Balance (€)",
              hintText: "Example: 120.00",
            ),
          ),
          actions: [
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final value = double.tryParse(controller.text) ?? -1;

                if (value < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid amount"),
                    ),
                  );
                  return;
                }

                final uuid = const Uuid();
                final model = TillBalance(
                  id: uuid.v4(),
                  balanceAmount: value,
                  balanceDate: today,
                  shopId: AppState.requireShopId(),
                );

                final repo = TillBalanceRepository(DatabaseService.instance);
                await repo.insertTillBalance(model);
                SyncService.instance.syncTillbalance();
                Navigator.pop(context, true);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
