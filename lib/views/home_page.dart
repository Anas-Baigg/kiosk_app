import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/admin_auth_service.dart';
import 'package:kiosk_app/services/download_service.dart';
import 'package:kiosk_app/services/home_tile.dart';
import 'package:kiosk_app/ui/download_ui.dart';
import 'package:kiosk_app/ui/sync_ui.dart';
import 'package:kiosk_app/views/transactions.dart';
import 'package:kiosk_app/ui/gradient_scaffold.dart';
import 'clocks_dialogs.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSyncing = false;
  bool _isSyncingDownlaod = false;
  final shopId = AppState.shopId;
  final shopName = AppState.shopName;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;

    return UniversalScaffold(
      title: shopName!.toUpperCase(),
      actions: [
        IconButton(
          icon: const Icon(Icons.admin_panel_settings_outlined, size: 25),
          tooltip: 'Admin Settings',
          onPressed: () {
            AdminAuthService.showAdminAccessDialog(context);
          },
        ),
        _isSyncing
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.cloud_sync_outlined),
                tooltip: 'Sync to Cloud',
                onPressed: () => SyncUIService.performSync(context, (val) {
                  setState(() => _isSyncing = val);
                }),
              ),

        _isSyncingDownlaod
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.download_for_offline_outlined),
                tooltip: 'Download to Cloud',
                onPressed: () =>
                    DownloadUIService.performDownload(context, (val) {
                      setState(() => _isSyncingDownlaod = val);
                    }),
              ),
      ],
      showLogout: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 2,
            children: [
              HomeTileButton(
                icon: Icons.login,
                label: "Clock IN",
                onPressed: () {
                  ClockDialog.showClocksDialog(
                    context,
                    ClockDialogAction.clockIn,
                  );
                },
              ),
              HomeTileButton(
                icon: Icons.logout,
                label: "Clock OUT",
                onPressed: () {
                  ClockDialog.showClocksDialog(
                    context,
                    ClockDialogAction.clockOut,
                  );
                },
              ),
              HomeTileButton(
                icon: Icons.cut_sharp,
                label: "Transactions",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Transactions()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
