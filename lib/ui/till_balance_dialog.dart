import 'package:flutter/material.dart';
import 'package:kiosk_app/components/till_balance.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/database_service.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:uuid/uuid.dart';

class TillBalanceDialog {
  static Future<bool> checkAndShow(BuildContext context) async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final db = DatabaseService.instance;

    final existing = await db.getTillBalanceByDate(todayMidnight);

    // If today already has a balance  nothing to do
    if (existing != null) return true;

    // Show dialog and wait for result
    final result = await _showOpeningDialog(context, todayMidnight);

    return result ?? false;
  }

  /// INTERNAL: Show modal dialog
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
                  // invalid input
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid amount"),
                    ),
                  );
                  return;
                }

                // Create model
                final uuid = const Uuid();

                final model = TillBalance(
                  id: uuid.v4(),
                  balanceAmount: value,
                  balanceDate: today,
                  shopId: AppState.requireShopId(),
                );

                // Save the record
                await DatabaseService.instance.insertTillBalance(model);
                final syncService = SyncService.instance;
                syncService.syncTillbalance();
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
