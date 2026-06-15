import 'package:flutter/material.dart';
import 'package:kiosk_app/models/till_balance.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/database/database_service.dart';
import 'package:kiosk_app/services/database/repositories/till_balance_repository.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:kiosk_app/utils/app_theme.dart';
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
              backgroundColor: AppColors.surfaceHigh,
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "Opening Balance",
                      style: AppTextStyles.titleMd().copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      "How much cash is in the till?",
                      style: AppTextStyles.bodySm(),
                    ),
                  ),
                ],
              ),
              content: success
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 70,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Balance recorded!",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLg().copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
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
                            style: AppTextStyles.price().copyWith(fontSize: 32),
                            decoration: InputDecoration(
                              hintText: "0.00",
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 16, right: 8),
                                child: Text(
                                  "€",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 16,
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
                              style: AppTextStyles.bodySm().copyWith(
                                color: AppColors.error,
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
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.outlineVariant,
                          ),
                          foregroundColor: AppColors.onSurface,
                        ),
                        child: const Text("Skip"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final value = double.tryParse(controller.text) ?? -1;

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

                          final repo = TillBalanceRepository(
                            DatabaseService.instance,
                          );
                          await repo.insertTillBalance(model);
                          SyncService.instance.syncTillbalance();

                          setState(() => success = true);
                          await Future.delayed(const Duration(seconds: 1));
                          if (context.mounted) Navigator.pop(context, true);
                        },
                        child: const Text("Confirm"),
                      ),
                    ],
            );
          },
        );
      },
    );
  }
}
