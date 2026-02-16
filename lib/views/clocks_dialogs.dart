import 'package:flutter/material.dart';
import 'package:kiosk_app/services/sync_service.dart';
import '../services/database_service.dart';

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
        Color feedbackColor = Colors.red;
        bool success = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Center(
                child: Text(
                  isIn ? "Clock In" : "Clock Out",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIn ? Colors.green[600] : Colors.red[600],
                    fontSize: 22,
                  ),
                ),
              ),

              content: success
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 70,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isIn
                              ? "Clocked in successfully!"
                              : "Clocked out successfully!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                            controller: passController,
                            decoration: InputDecoration(
                              labelText: "Enter Your Passcode",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Please enter your 5-digit passcode.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          if (feedback != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              feedback!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
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
                      FilledButton.tonal(
                        onPressed: () => Navigator.pop(context, false),
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
                              feedbackColor = Colors.red;
                            });
                            return;
                          }
                          final db = DatabaseService.instance;
                          final empId = await db.getEmployeeIdByPasscode(raw);
                          if (empId == null) {
                            setState(() {
                              feedback =
                                  "Wrong passcode or employee not registered.";
                              feedbackColor = Colors.red;
                            });
                            return;
                          }

                          if (isIn) {
                            final res = await db.clockIn(empId);
                            if (res == -1) {
                              setState(() {
                                feedback = "You already have an open shift";
                                feedbackColor = Colors.red;
                              });
                              return;
                            }

                            setState(() {
                              success = true;
                            });

                            // Auto-sync time logs after clock in
                            final syncService = SyncService();
                            syncService.syncTimeLogs();

                            await Future.delayed(const Duration(seconds: 1));
                            Navigator.pop(context, true);
                          } else {
                            final ok = await db.clockOut(empId);
                            if (!ok) {
                              setState(() {
                                feedback = "You are not clocked in.";
                                feedbackColor = Colors.red;
                              });
                              return;
                            }
                            setState(() {
                              success = true;
                            });

                            // Auto-sync time logs after clock out
                            final syncService = SyncService();
                            syncService.syncTimeLogs();

                            await Future.delayed(const Duration(seconds: 1));
                            Navigator.pop(context, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isIn
                              ? Colors.green[600]
                              : Colors.red[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          isIn ? "Clock In" : "Clock Out",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
    passController.dispose();
    return result;
  }
}
