import 'package:flutter/material.dart';
import 'package:kiosk_app/components/cart_Item.dart';
import 'package:kiosk_app/components/cuts.dart';

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
        const Text("Services", style: TextStyle(fontSize: 18)),
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
                    title: Text(cut.cutname),
                    subtitle: Text("€${cut.price}"),
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
                          onPressed: () =>
                              onIncrement(key, cut.cutname, cut.price!),
                          icon: const Icon(Icons.add),
                          color: Colors.black,
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
