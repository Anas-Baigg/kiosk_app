import 'package:flutter/material.dart';
import 'package:kiosk_app/models/cart_item.dart';
import 'package:kiosk_app/models/products.dart';
import 'package:kiosk_app/utils/app_theme.dart';

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
        Text("Products", style: AppTextStyles.titleMd()),
        FutureBuilder<List<Product>>(
          future: productsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final productList = snapshot.data!;

            return Flexible(
              fit: FlexFit.loose,
              child: ListView.separated(
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  final product = productList[index];
                  final key = "product_${product.id}";

                  return ListTile(
                    title: Text(
                      product.productName,
                      style: AppTextStyles.bodyLg(),
                    ),
                    subtitle: Text(
                      "€${product.price}",
                      style: AppTextStyles.labelCaps(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => onDecrement(key),
                          icon: const Icon(Icons.remove),
                          color: AppColors.onSurfaceVariant,
                        ),
                        Text(
                          "${cartItems[key]?.quantity ?? 0}",
                          style: AppTextStyles.price().copyWith(fontSize: 16),
                        ),
                        IconButton(
                          onPressed: () => onIncrement(
                            key,
                            product.productName,
                            product.price!,
                          ),
                          icon: const Icon(Icons.add),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider(thickness: 1, height: 1);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
