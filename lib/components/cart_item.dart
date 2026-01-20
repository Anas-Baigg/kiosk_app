// ignore_for_file: file_names

class CartItem {
  final String idKey;
  final String name;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.idKey,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get subtotal => unitPrice * quantity;
}
