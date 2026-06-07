import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/utils/app_constants.dart';
import 'package:kiosk_app/utils/app_theme.dart';
import 'package:kiosk_app/screens/auth_screen.dart';
import 'package:kiosk_app/screens/shop_selection_screen.dart';
import 'package:kiosk_app/screens/shop_storage.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:kiosk_app/views/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
  SyncService.instance.initConnectivityMonitoring();

  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Cached so repeated auth state events (silent token refresh) don't re-read
  // SharedPreferences. Reset to null on logout so the next login gets fresh data.
  static Future<void>? _loadFuture;

  Future<void> _loadShopIntoMemory() async {
    AppState.shopId = await ShopStorage.getShopId();
    AppState.shopName = await ShopStorage.getShopName();
    AppState.adminPasswordHash = await ShopStorage.getAdminPasswordHash();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          debugPrint('Auth state: ${snapshot.data?.event}');
          final session = snapshot.data?.session;

          if (session == null) {
            MyApp._loadFuture = null; // Reset so next login re-reads SharedPreferences
            return const AuthScreen();
          }
          return FutureBuilder<void>(
            future: MyApp._loadFuture ??= _loadShopIntoMemory(),
            builder: (context, shopSnap) {
              if (shopSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final shopId = AppState.shopId;
              final adminPassword = AppState.adminPasswordHash;
              if (shopId != null &&
                  shopId.isNotEmpty &&
                  adminPassword != null) {
                return const HomePage();
              }
              return const ShopSelectionScreen();
            },
          );
        },
      ),
    );
  }
}
