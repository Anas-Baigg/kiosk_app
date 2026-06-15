import 'package:flutter/material.dart';
import 'package:kiosk_app/models/cart_item.dart';
import 'package:kiosk_app/models/cuts.dart';
import 'package:kiosk_app/utils/app_theme.dart';

class ServiceList extends StatelessWidget {
  final Future<List<Cuts>> cutsFuture;
  final Map<String, CartItem> cartItems;
  final Function(String idKey, String name, double price) onIncrement;
  final Function(String idKey) onDecrement;

  const ServiceList({
    super.key,
    required this.cutsFuture,
    required this.cartItems,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Services", style: AppTextStyles.titleMd()),
        FutureBuilder<List<Cuts>>(
          future: cutsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final cutsList = snapshot.data!;

            return Flexible(
              fit: FlexFit.loose,
              child: ListView.separated(
                itemCount: cutsList.length,
                itemBuilder: (context, i) {
                  final cut = cutsList[i];
                  final key = "cut_${cut.id}";

                  return ListTile(
                    title: Text(cut.cutname, style: AppTextStyles.bodyLg()),
                    subtitle: Text(
                      "€${cut.price}",
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
                          onPressed: () =>
                              onIncrement(key, cut.cutname, cut.price!),
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
