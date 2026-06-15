import 'package:flutter/material.dart';
import 'package:kiosk_app/services/database/database_service.dart';
import 'package:kiosk_app/services/database/repositories/employee_repository.dart';
import 'package:kiosk_app/services/database/repositories/time_log_repository.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:kiosk_app/utils/app_theme.dart';

enum ClockDialogAction { clockIn, clockOut }

class ClockDialog {
  static Future<bool?> showClocksDialog(
    BuildContext context,
    ClockDialogAction action,
  ) async {
    final TextEditingController passController = TextEditingController();
    final bool isIn = action == ClockDialogAction.clockIn;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String? feedback;
        Color feedbackColor = AppColors.error;
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
              title: Center(
                child: Text(
                  isIn ? "Clock In" : "Clock Out",
                  style: AppTextStyles.titleMd().copyWith(
                    color: AppColors.primary,
                  ),
                ),
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
                          isIn
                              ? "Clocked in successfully!"
                              : "Clocked out successfully!",
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
                          Text("PASSCODE", style: AppTextStyles.labelCaps()),
                          const SizedBox(height: 6),
                          TextField(
                            controller: passController,
                            decoration: const InputDecoration(
                              hintText: "Enter your passcode",
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            style: AppTextStyles.bodyLg(),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Please enter your 5-digit passcode.",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySm(),
                          ),
                          if (feedback != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              feedback!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySm().copyWith(
                                color: feedbackColor,
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
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final raw = passController.text.trim();
                          final passcode = int.tryParse(raw);
                          if (passcode == null) {
                            setState(() {
                              feedback =
                                  "Please enter a valid numeric passcode.";
                              feedbackColor = AppColors.error;
                            });
                            return;
                          }
                          final empRepo =
                              EmployeeRepository(DatabaseService.instance);
                          final timeRepo =
                              TimeLogRepository(DatabaseService.instance);
                          final empId =
                              await empRepo.getEmployeeIdByPasscode(raw);
                          if (empId == null) {
                            setState(() {
                              feedback =
                                  "Wrong passcode or employee not registered.";
                              feedbackColor = AppColors.error;
                            });
                            return;
                          }

                          if (isIn) {
                            final res = await timeRepo.clockIn(empId);
                            if (res == -1) {
                              setState(() {
                                feedback = "You already have an open shift";
                                feedbackColor = AppColors.error;
                              });
                              return;
                            }

                            setState(() => success = true);
                            SyncService.instance.syncTimeLogs();
                            await Future.delayed(const Duration(seconds: 1));
                            if (context.mounted) Navigator.pop(context, true);
                          } else {
                            final ok = await timeRepo.clockOut(empId);
                            if (!ok) {
                              setState(() {
                                feedback = "You are not clocked in.";
                                feedbackColor = AppColors.error;
                              });
                              return;
                            }
                            setState(() => success = true);
                            SyncService.instance.syncTimeLogs();
                            await Future.delayed(const Duration(seconds: 1));
                            if (context.mounted) Navigator.pop(context, true);
                          }
                        },
                        child: Text(isIn ? "Clock In" : "Clock Out"),
                      ),
                    ],
            );
          },
        );
      },
    );

    return result;
  }
}
