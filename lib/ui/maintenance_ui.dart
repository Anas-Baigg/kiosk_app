import 'package:flutter/material.dart';
import 'package:kiosk_app/services/download_service.dart';
import 'package:kiosk_app/services/sync_service.dart';

class MaintenanceUIService {
  static Future<void> performMaintenance(
    BuildContext context,
    Function(bool) setSyncing, {
    int historyDays = 30,
  }) async {
    setSyncing(true);

    final syncService = SyncService.instance;
    final pullService = PullService();

    //Internet check once
    if (!await syncService.isOnline()) {
      setSyncing(false);
      if (!context.mounted) return;
      _showErrorDialog(
        context,
        "No connection.\n\nData is safe locally. Sync/Download will work when Wi-Fi returns.",
        title: "No Internet",
      );
      return;
    }

    bool syncOk = false;
    bool pullOk = false;

    try {
      //sync local unsynced changes to cloud
      syncOk = await syncService.syncAll();
      if (!context.mounted) return;

      if (!syncOk) {
        _showErrorDialog(
          context,
          "Cloud sync failed.\n\nYour data is still safe locally. Please try again when the connection is stable.",
          title: "Sync Failed",
        );
        return; //stop here don't pull when push failed
      }

      //download latest cloud data into local
      pullOk = await pullService.fullDownloadFromCloud(
        historyDays: historyDays,
      );
      if (!context.mounted) return;

      if (pullOk) {
        _showSuccessDialog(context);
      } else {
        // Partial success: push succeeded, pull failed
        _showPartialDialog(
          context,
          title: "Uploaded, but Download Failed",
          message:
              "Your local changes were uploaded successfully.\n\nHowever, downloading updates from the cloud failed. You can try again later.",
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      // If sync already succeeded, show partial info instead of generic failure
      if (syncOk && !pullOk) {
        _showPartialDialog(
          context,
          title: "Uploaded, but Download Failed",
          message:
              "Your local changes were uploaded successfully.\n\nBut downloading updates failed with:\n\n$e",
        );
      } else {
        _showErrorDialog(context, e.toString(), title: "Maintenance Failed");
      }
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
              "Maintenance Complete",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your kiosk synced and downloaded the latest data.",
              textAlign: TextAlign.center,
            ),
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

  static void _showPartialDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_done_outlined, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(
    BuildContext context,
    String error, {
    String title = "Error",
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
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
