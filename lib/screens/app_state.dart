class AppState {
  static String? shopId;
  static String? shopName;
  static String? adminPasswordHash;

  static String requireShopId() {
    final id = shopId;
    if (id == null || id.isEmpty) {
      throw StateError('No shop selected (AppState.shopId is null/empty).');
    }
    return id;
  }
}
