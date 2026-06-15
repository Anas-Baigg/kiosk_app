import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/screens/shop_storage.dart';
import 'package:kiosk_app/services/realtime_service.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:kiosk_app/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UniversalScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final bool showLogout;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const UniversalScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showLogout = false,
    this.actions,
    this.floatingActionButton,
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
        title: Text('Logout', style: AppTextStyles.titleMd()),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodySm(),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.outlineVariant),
              foregroundColor: AppColors.onSurface,
            ),
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
      backgroundColor: AppColors.background,
      floatingActionButton: widget.floatingActionButton,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        title: Text(
          widget.title,
          style: AppTextStyles.titleMd().copyWith(letterSpacing: 1.2),
        ),
        foregroundColor: AppColors.onSurface,
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
        decoration: const BoxDecoration(color: AppColors.background),
        child: Column(
          children: [
            ValueListenableBuilder<ConnectivityStatus>(
              valueListenable: SyncService.instance.connectivityStatus,
              builder: (context, status, _) {
                final isOnline = status == ConnectivityStatus.online;
                final isOffline = status == ConnectivityStatus.offline;
                final iconColor = isOffline
                    ? AppColors.warning
                    : AppColors.error;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isOnline ? 0 : 40,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHighest,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: isOnline
                      ? const SizedBox.shrink()
                      : InkWell(
                          onTap: isOffline
                              ? null
                              : () => SyncService.instance.syncAll(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  isOffline
                                      ? Icons.wifi_off
                                      : Icons.cloud_off,
                                  color: iconColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isOffline
                                        ? "Offline — changes save locally"
                                        : "Sync failed — tap to retry",
                                    style: AppTextStyles.labelCaps().copyWith(
                                      color: iconColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                );
              },
            ),
            Expanded(child: widget.body),
          ],
        ),
      ),
    );
  }
}
