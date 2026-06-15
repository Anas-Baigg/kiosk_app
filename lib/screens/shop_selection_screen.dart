import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/screens/shop_storage.dart';
import 'package:kiosk_app/services/download_service.dart';
import 'package:kiosk_app/utils/app_theme.dart';
import 'package:kiosk_app/utils/validators/shop_validators.dart';
import 'package:kiosk_app/widgets/gradient_scaffold.dart';
import 'package:kiosk_app/views/home_page.dart';
import 'package:kiosk_app/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

class ShopSelectionScreen extends StatefulWidget {
  const ShopSelectionScreen({super.key});

  @override
  State<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends State<ShopSelectionScreen> {
  final _supabase = Supabase.instance.client;
  final _shopNameController = TextEditingController();
  final _adminPassController = TextEditingController();
  final _createFormKey = GlobalKey<FormState>();

  List<dynamic> _shops = [];
  bool _isLoading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchShops() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are not logged in.')));
      return;
    }

    try {
      final data = await _supabase
          .from('shops')
          .select('id, name, admin_password_hash')
          .eq('owner_id', user.id)
          .order('name');

      if (!mounted) return;
      setState(() {
        _shops = data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching shops: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching shops: $e')));
    }
  }

  Future<void> _createShop() async {
    FocusScope.of(context).unfocus();
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final ok = _createFormKey.currentState?.validate() ?? false;
    if (!ok) return;
    final name = _shopNameController.text.trim();
    final rawPin = _adminPassController.text.trim();
    final hashedPin = BCrypt.hashpw(rawPin, BCrypt.gensalt());
    setState(() => _creating = true);
    try {
      await _supabase.from('shops').insert({
        'name': name,
        'owner_id': user.id,
        'admin_password_hash': hashedPin,
      });

      _shopNameController.clear();
      _adminPassController.clear();
      _createFormKey.currentState?.reset();
      await _fetchShops();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shop created')));
    } catch (e) {
      debugPrint('Error creating shop: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating shop: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _selectShop(dynamic shop) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Fetching Shop Data..."),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final id = shop['id'].toString();
      final name = (shop['name'] ?? '').toString();
      final adminPasswordHash = (shop['admin_password_hash']) as String?;
      AppState.shopId = id;
      AppState.shopName = name;
      AppState.adminPasswordHash = adminPasswordHash;
      await ShopStorage.saveShop(
        id: id,
        name: name,
        adminPasswordHash: adminPasswordHash ?? '',
      );
      await PullService().fullDownloadFromCloud();
      await RealtimeService.instance.subscribe();
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close Dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return UniversalScaffold(
      title: 'Select Your Shop',
      showLogout: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final maxWidth = isWide ? 640.0 : double.infinity;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 24 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Select Shop',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMd().copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a shop to continue, or create a new one below.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm(),
                        ),
                        const SizedBox(height: 18),

                        // Shops list
                        if (_shops.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.store_outlined,
                                  size: 44,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No shops yet',
                                  style: AppTextStyles.titleMd(),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Create your first shop using the form below.',
                                  style: AppTextStyles.bodySm(),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _shops.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final shop = _shops[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.storefront,
                                    color: AppColors.primary,
                                  ),
                                  title: Text(
                                    shop['name'] ?? '',
                                    style: AppTextStyles.bodyLg(),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.outlineVariant,
                                  ),
                                  onTap: () => _selectShop(shop),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 20),
                        const Divider(color: AppColors.outlineVariant),
                        const SizedBox(height: 12),

                        Text(
                          'Create a New Shop',
                          style: AppTextStyles.titleMd().copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Form(
                          key: _createFormKey,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _shopNameController,
                                  textInputAction: TextInputAction.done,
                                  keyboardType: TextInputType.name,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: ShopValidators.shopName,
                                  onFieldSubmitted: (_) =>
                                      _creating ? null : _createShop(),
                                  decoration: const InputDecoration(
                                    hintText: 'New shop name',
                                    labelText: 'Shop Name',
                                    prefixIcon: Icon(Icons.add_business),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _adminPassController,
                                  textInputAction: TextInputAction.done,
                                  keyboardType: TextInputType.number,

                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: ShopValidators.adminPassword,

                                  onFieldSubmitted: (_) =>
                                      _creating ? null : _createShop(),
                                  decoration: const InputDecoration(
                                    hintText: '5-Digit Admin Pass',
                                    labelText: 'Admin Password',
                                    prefixIcon: Icon(
                                      Icons.add_moderator_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 48,
                                child: _creating
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _createShop,
                                        child: const Text('Create'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
