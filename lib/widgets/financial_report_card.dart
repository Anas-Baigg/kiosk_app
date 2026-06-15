import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiosk_app/models/daily_finance.dart';
import 'package:kiosk_app/utils/app_theme.dart';

class FinancialReportCard extends StatelessWidget {
  final int totalTransactions;
  final double totalCash;
  final double totalCard;
  final Map<String, double> tipsPerEmployee;
  final List<DailyFinance> dailyFinance;

  const FinancialReportCard({
    super.key,
    required this.totalTransactions,
    required this.totalCash,
    required this.totalCard,
    required this.tipsPerEmployee,
    required this.dailyFinance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Financial Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _summaryTile("Transactions", totalTransactions.toString(), AppColors.primary)),
                Expanded(child: _summaryTile("Cash", "€${totalCash.toStringAsFixed(2)}", AppColors.success)),
                Expanded(child: _summaryTile("Card", "€${totalCard.toStringAsFixed(2)}", AppColors.primary)),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Tips Per Employee",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            ...tipsPerEmployee.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  "${e.key}: €${e.value.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),

            const Text(
              "Daily Breakdown",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Row(
              children: const [
                Expanded(child: Text("Date", style: _headerStyle)),
                Text("Cash", style: _headerStyle),
                SizedBox(width: 16),
                Text("Card", style: _headerStyle),
                SizedBox(width: 16),
                Text("Till", style: _headerStyle),
              ],
            ),

            const Divider(),

            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: dailyFinance.length,
                itemBuilder: (context, index) {
                  final d = dailyFinance[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(DateFormat('yyyy-MM-dd').format(d.date))),
                        Text("€${d.cashTotal.toStringAsFixed(2)}"),
                        const SizedBox(width: 16),
                        Text("€${d.cardTotal.toStringAsFixed(2)}"),
                        const SizedBox(width: 16),
                        Text("€${d.tillBalance.toStringAsFixed(2)}"),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

const _headerStyle = TextStyle(
  fontWeight: FontWeight.w600,
  color: AppColors.onSurfaceVariant,
);
