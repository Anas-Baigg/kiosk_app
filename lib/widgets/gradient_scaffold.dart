import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/screens/shop_storage.dart';
import 'package:kiosk_app/services/realtime_service.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UniversalScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final bool showLogout;
  final List<Widget>? actions;

  const UniversalScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showLogout = false,
    this.actions,
  });

  @override
  State<UniversalScaffold> createState() => _UniversalScaffoldState();
}

class _UniversalScaffoldState extends State<UniversalScaffold> {
  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);

    AppState.shopId = null;
    AppState.shopName = null;
    AppState.adminPasswordHash = null;

    try {
      await ShopStorage.clear();
      await RealtimeService.instance.unsubscribe();
      await Supabase.instance.client.auth.signOut();
      navigator.pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      debugPrint("Logout failed: $e");
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.title),
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Color(0xFF37393F)),
        ),
        foregroundColor: Colors.white,
        actions: [
          if (widget.actions != null) ...widget.actions!,
          if (widget.showLogout)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFD8DBE2)),
        child: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: ValueListenableBuilder<ConnectivityStatus>(
                valueListenable: SyncService.instance.connectivityStatus,
                builder: (context, status, _) {
                  if (status == ConnectivityStatus.online) {
                    return const SizedBox.shrink();
                  }
                  final isOffline = status == ConnectivityStatus.offline;
                  return GestureDetector(
                    onTap: isOffline
                        ? null
                        : () => SyncService.instance.syncAll(),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isOffline ? Colors.orange[50] : Colors.red[50],
                        border: Border.all(
                          color: isOffline
                              ? Colors.orange[300]!
                              : Colors.red[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOffline ? Icons.wifi_off : Icons.cloud_off,
                            color: isOffline
                                ? Colors.orange[700]
                                : Colors.red[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isOffline
                                  ? "Working offline — data saves locally"
                                  : "Sync failed — tap to retry",
                              style: TextStyle(
                                color: isOffline
                                    ? Colors.orange[800]
                                    : Colors.red[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(child: widget.body),
          ],
        ),
      ),
    );
  }
}
