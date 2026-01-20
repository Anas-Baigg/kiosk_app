class ValidatorsShopName {
  ValidatorsShopName._();

  static final RegExp _passcodeRegex = RegExp(r'^\d{5}$');
  static String? shopName(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) return 'Shop name is required';
    if (v.length < 3) return 'Shop name must be at least 3 characters';
    if (v.length > 40) return 'Shop name must be 40 characters or less';

    // Only allow letters and spaces
    final ok = RegExp(r"^[a-zA-Z ]+$").hasMatch(v);
    if (!ok) return "Only letters and spaces are allowed";

    return null;
  }

  static String? adminPassword(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Admin Password is required';
    if (!_passcodeRegex.hasMatch(v)) {
      return 'Passcode must be exactly 5 digits';
    }
    return null;
  }
}
