class ProductValidators {
  static final RegExp _productName = RegExp(r'^[a-zA-Z\s]+$');

  static String? validateProductName(String? raw) {
    final product = (raw ?? '').trim();
    if (product.isEmpty) return 'Product Name cant be empty';
    if (!_productName.hasMatch(product)) {
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
    final re = RegExp(r'^(?:\d+|\d*\.\d{1,2})$');
    if (!re.hasMatch(normalized)) {
      return 'Enter a valid price (up to 2 decimals)';
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Price cannot be negative';
    return null;
  }
}
