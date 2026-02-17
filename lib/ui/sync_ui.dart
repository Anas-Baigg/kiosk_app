import 'package:flutter/material.dart';
import 'package:kiosk_app/services/sync_service.dart';

class SyncUIService {
  static Future<void> performSync(
    BuildContext context,
    Function(bool) setSyncing,
  ) async {
    setSyncing(true);

    final syncService = SyncService.instance;

    // 1. Check internet first
    if (!await syncService.isOnline()) {
      setSyncing(false);
      _showErrorDialog(
        context,
        "No connection. Data is safe locally and will sync when Wi-Fi returns.",
      );
      return;
    }

    try {
      bool success = await syncService.syncAll();
      if (!context.mounted) return;

      if (success) {
        _showSuccessDialog(context);
      } else {
        _showErrorDialog(context, "Sync encountered an error.");
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorDialog(context, e.toString());
    } finally {
      setSyncing(false);
    }
  }

  static void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              "Cloud Sync Complete",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text("Your business data is now up to date."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "Awesome",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Sync Failed"),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
