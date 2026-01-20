import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/screens/shop_storage.dart';
import 'package:kiosk_app/services/download_service.dart';
import 'package:kiosk_app/services/shop_name.dart';
import 'package:kiosk_app/ui/gradient_scaffold.dart';
import 'package:kiosk_app/views/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          .select('id, name, admin_password')
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
    final adminPassword = int.parse(_adminPassController.text.trim());
    setState(() => _creating = true);
    try {
      await _supabase.from('shops').insert({
        'name': name,
        'owner_id': user.id,
        'admin_password': adminPassword,
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
      final adminPassword = (shop['admin_password']);
      AppState.shopId = id;
      AppState.shopName = name;
      AppState.adminPassword = adminPassword;
      await ShopStorage.saveShop(
        id: id,
        name: name,
        adminPassword: adminPassword,
      );
      await PullService().fullDownloadFromCloud();
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
                  child: Card(
                    elevation: isWide ? 10 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isWide ? 24 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isWide) ...[
                            Text(
                              'Choose a shop to continue',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You can also create a new shop below.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Shops list
                          if (_shops.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  const Icon(Icons.store_outlined, size: 44),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No shops yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Create your first shop using the form below.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final shop = _shops[index];
                                return ListTile(
                                  leading: const Icon(Icons.store),
                                  title: Text(shop['name'] ?? ''),
                                  subtitle: Text('ID: ${shop['id']}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _selectShop(shop),
                                );
                              },
                            ),

                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 14),

                          Text(
                            'Create a new shop',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
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
                                    validator: ValidatorsShopName.shopName,
                                    onFieldSubmitted: (_) =>
                                        _creating ? null : _createShop(),
                                    decoration: InputDecoration(
                                      hintText: 'New shop name',
                                      prefixIcon: const Icon(
                                        Icons.add_business,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                                    validator: ValidatorsShopName.adminPassword,

                                    onFieldSubmitted: (_) =>
                                        _creating ? null : _createShop(),
                                    decoration: InputDecoration(
                                      hintText: '5-Digit Admin Pass',
                                      labelText: 'Admin Password',
                                      prefixIcon: const Icon(
                                        Icons.add_moderator_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
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
            ),
          );
        },
      ),
    );
  }
}
