import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiosk_app/components/transactionModel.dart';
import 'package:kiosk_app/components/transaction_item.dart';
import 'package:kiosk_app/services/database_service.dart';

class TransactionListWidget extends StatelessWidget {
  // We pass the future to the widget, which contains the list filtered by the parent.
  final Future<List<TransactionHeader>> transactionsFuture;
  final DatabaseService database;

  const TransactionListWidget({
    super.key,
    required this.transactionsFuture,
    required this.database,
  });

  // --- Helper for displaying detail rows in the dialog ---
  Widget _buildDetailRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isDiscount ? Colors.redAccent : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
              color: isDiscount
                  ? Colors.redAccent
                  : (isTotal ? Colors.indigo.shade800 : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // --- Function to show the detailed breakdown of a transaction ---
  void _showTransactionDetails(BuildContext context, TransactionHeader header) {
    showDialog(
      context: context,
      builder: (context) {
        // Use a FutureBuilder to fetch the line items on demand
        return FutureBuilder<List<TransactionItem>>(
          future: database.getItemsForTransaction(header.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data ?? [];
            final hasError = snapshot.hasError;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Transaction Details',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Item loading errors
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Error loading items: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Summary Section
                    _buildDetailRow("Employee Name:", header.employeeName!),
                    _buildDetailRow("Payment:", header.paymentMethod),
                    _buildDetailRow(
                      "Date:",
                      DateFormat('MMM dd, hh:mm a').format(header.timestamp),
                    ),
                    const Divider(),

                    // Items Section
                    const Text(
                      "Items Sold:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Text(
                          "No items recorded for this transaction.",
                          style: TextStyle(color: Colors.black),
                        ),
                      )
                    else
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text(
                            "${item.quantity}x ${item.itemName} (${item.itemType}) Price ${item.unitPrice.toStringAsFixed(2)}",
                          ),
                        ),
                      ),
                    const Divider(),

                    // Financial Breakdown
                    _buildDetailRow(
                      "Base Total:",
                      "€${header.baseTotal.toStringAsFixed(2)}",
                    ),
                    _buildDetailRow(
                      "Discount:",
                      "-€${header.discount.toStringAsFixed(2)}",
                      isDiscount: true,
                    ),
                    _buildDetailRow(
                      "Tip:",
                      "+€${header.tip.toStringAsFixed(2)}",
                    ),
                    const Divider(color: Colors.black, thickness: 1.5),
                    _buildDetailRow(
                      "FINAL TOTAL:",
                      "€${header.finalTotal.toStringAsFixed(2)}",
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TransactionHeader>>(
      future: transactionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading transactions: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No transactions found for the selected date range.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          );
        }

        final transactions = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Transaction History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];

                  final formattedDate = DateFormat(
                    'yyyy-MM-dd HH:mm',
                  ).format(tx.timestamp);

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 8.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: tx.paymentMethod == 'Cash'
                            ? Colors.green[100]
                            : Colors.blue[100],
                        child: Icon(
                          tx.paymentMethod == 'Cash'
                              ? Icons.money
                              : Icons.credit_card,
                          color: tx.paymentMethod == 'Cash'
                              ? Colors.green[800]
                              : Colors.blue[800],
                        ),
                      ),
                      title: Text(
                        "Transaction #${tx.id}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date: $formattedDate"),
                          Text("Employee: ${tx.employeeName}"),
                        ],
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "€${tx.finalTotal.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.purple[700],
                            ),
                          ),
                          Text(
                            tx.paymentMethod,
                            style: TextStyle(
                              fontSize: 12,
                              color: tx.paymentMethod == 'Cash'
                                  ? Colors.green[600]
                                  : Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showTransactionDetails(context, tx),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
