import 'package:flutter/material.dart';
import 'package:kiosk_app/utils/app_theme.dart';

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

  static final _labelStyle = AppTextStyles.titleMd().copyWith(
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

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
                child: Text("Cash", style: _labelStyle),
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
                child: Text("Card", style: _labelStyle),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
