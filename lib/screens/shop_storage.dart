import 'package:shared_preferences/shared_preferences.dart';

class ShopStorage {
  static const _kShopId = 'selected_shop_id';
  static const _kShopName = 'selected_shop_name';
  static const _kAdminPasswordHash = 'selected_admin_password_hash';

  static Future<void> saveShop({
    required String id,
    required String name,
    String? adminPasswordHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kShopId, id);
    await prefs.setString(_kShopName, name);
    if (adminPasswordHash != null) {
      await prefs.setString(_kAdminPasswordHash, adminPasswordHash);
    }
  }

  static Future<String?> getShopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kShopId);
  }

  static Future<String?> getShopName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kShopName);
  }

  static Future<String?> getAdminPasswordHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAdminPasswordHash);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kShopId);
    await prefs.remove(_kShopName);
    await prefs.remove(_kAdminPasswordHash);
  }
}
