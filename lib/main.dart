import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
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
  Future<void> _loadShopIntoMemory() async {
    AppState.shopId = await ShopStorage.getShopId();
    AppState.shopName = await ShopStorage.getShopName();
    AppState.adminPasswordHash = await ShopStorage.getAdminPasswordHash();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crazy Cutz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // White/light base
        scaffoldBackgroundColor: Colors.black,
        //a consistent palette from your brand color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(55, 63, 81, 1.0),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 9,
          titleTextStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontFamily: "RobotoMono",
            color: Colors.white,
          ),
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          debugPrint('Auth state: ${snapshot.data?.event}');
          final session = snapshot.data?.session;

          if (session == null) {
            return const AuthScreen();
          }
          return FutureBuilder<void>(
            future: _loadShopIntoMemory(),
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
