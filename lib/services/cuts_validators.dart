class CutsValidators {
  static final RegExp _cuTRegex = RegExp(r'^[a-zA-Z\s]+$');
  static final RegExp _re = RegExp(r'^(?:\d+|\d*\.\d{1,2})$');

  static String? validateCutName(String? raw) {
    final cut = (raw ?? '').trim();
    if (cut.isEmpty) return 'Cut Name cant be empty';
    if (!_cuTRegex.hasMatch(cut)) {
      return 'Name must contain only alphabets';
    }
    return null;
  }

  static String? validatePrice(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Price is required';

    // Normalize decimal separator (optional)
    final normalized = value.replaceAll(',', '.');

    // Accept: 12, 12.3, 12.34, .99, 0.99
    if (!_re.hasMatch(normalized)) {
      return 'Enter a valid price (up to 2 decimals)';
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Price cannot be negative';
    return null;
  }
}
