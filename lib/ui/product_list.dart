import 'package:flutter/material.dart';
import 'package:kiosk_app/components/cart_Item.dart';
import 'package:kiosk_app/components/products.dart';

class ProductList extends StatelessWidget {
  final Future<List<Product>> productsFuture;
  final Map<String, CartItem> cartItems;
  final Function(String idKey, String name, double price) onIncrement;
  final Function(String idKey) onDecrement;

  const ProductList({
    super.key,
    required this.productsFuture,
    required this.cartItems,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Products", style: TextStyle(fontSize: 18)),
        FutureBuilder<List<Product>>(
          future: productsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final productList = snapshot.data!;

            return Flexible(
              fit: FlexFit.loose,
              child: ListView.builder(
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  final product = productList[index];
                  final key = "product_${product.id}";

                  return ListTile(
                    title: Text(product.productName),
                    subtitle: Text("€${product.price}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => onDecrement(key),
                          icon: const Icon(Icons.remove),
                          color: Colors.black,
                        ),
                        Text(
                          "${cartItems[key]?.quantity ?? 0}",
                          style: TextStyle(color: Colors.black),
                        ),
                        IconButton(
                          onPressed: () => onIncrement(
                            key,
                            product.productName,
                            product.price!,
                          ),
                          icon: const Icon(Icons.add),
                          color: Colors.black,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
