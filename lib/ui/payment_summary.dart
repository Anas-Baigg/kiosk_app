import 'package:flutter/material.dart';

class PaymentSummary extends StatelessWidget {
  final TextEditingController tipController;
  final TextEditingController discountController;
  final double baseTotal;
  final double finalTotal;
  final ValueChanged<String> onTipChanged;
  final ValueChanged<String> onDiscountChanged;
  final VoidCallback onConfirmCash;
  final VoidCallback onConfirmCard;

  const PaymentSummary({
    super.key,
    required this.tipController,
    required this.discountController,
    required this.baseTotal,
    required this.finalTotal,
    required this.onTipChanged,
    required this.onDiscountChanged,
    required this.onConfirmCash,
    required this.onConfirmCard,
  });
  static const _labelStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
    fontFamily: "RobotoMono",
    color: Color.fromARGB(255, 55, 63, 81),
  );
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // TIP + DISCOUNT
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                controller: tipController,
                decoration: const InputDecoration(
                  labelText: "Tip (€)",
                  border: OutlineInputBorder(),
                ),
                onChanged: onTipChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                controller: discountController,
                decoration: const InputDecoration(
                  labelText: "Discount (€)",
                  border: OutlineInputBorder(),
                ),
                onChanged: onDiscountChanged,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // PAYMENT BUTTONS
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                  ),
                ),
                onPressed: onConfirmCash,
                child: const Text("Cash", style: _labelStyle),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                  ),
                ),
                onPressed: onConfirmCard,
                child: const Text("Card", style: _labelStyle),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
