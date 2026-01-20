import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/screens/shop_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UniversalScaffold extends StatelessWidget {
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

  Future<void> _logout(BuildContext context) async {
    AppState.shopId = null;
    AppState.shopName = null;
    AppState.adminPassword = null;
    // Clear saved shop
    await ShopStorage.clear();

    // Sign out from Supabase
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    // Remove all routes and go to auth screen
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
        title: Text(title),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 55, 63, 81),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          if (actions != null) ...actions!,
          if (showLogout)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 216, 219, 226),
        ),
        child: body,
      ),
    );
  }
}
