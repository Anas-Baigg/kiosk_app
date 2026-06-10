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

    if (!context.mounted) return false;
    final result = await _showOpeningDialog(context, todayMidnight);

    return result ?? false;
  }

  static Future<bool?> _showOpeningDialog(
    BuildContext context,
    DateTime today,
  ) async {
    final TextEditingController controller = TextEditingController();

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        String? errorText;
        bool success = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "Opening Balance",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      "How much cash is in the till?",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              content: success
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 70,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Balance recorded!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: "0.00",
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 18,
                                ),
                                child: Text(
                                  "€",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.green[400]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.green[700]!,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.green[400]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 12,
                              ),
                            ),
                            onChanged: (_) {
                              if (errorText != null) {
                                setState(() => errorText = null);
                              }
                            },
                          ),
                          if (errorText != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              errorText!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: success
                  ? []
                  : [
                      FilledButton.tonal(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Skip"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () async {
                          final value =
                              double.tryParse(controller.text) ?? -1;

                          if (value < 0) {
                            setState(
                              () => errorText = "Please enter a valid amount",
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

                          final repo =
                              TillBalanceRepository(DatabaseService.instance);
                          await repo.insertTillBalance(model);
                          SyncService.instance.syncTillbalance();

                          setState(() => success = true);
                          await Future.delayed(const Duration(seconds: 1));
                          if (context.mounted) Navigator.pop(context, true);
                        },
                        child: const Text(
                          "Confirm",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }
}
