import 'package:flutter/material.dart';
import 'package:kiosk_app/components/cart_Item.dart';
import 'package:kiosk_app/components/cuts.dart';
import 'package:kiosk_app/components/products.dart';
import 'package:kiosk_app/components/transaction_item.dart';
import 'package:kiosk_app/components/transactionModel.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:kiosk_app/ui/employee_dropdown.dart';
import 'package:kiosk_app/ui/gradient_scaffold.dart';
import 'package:kiosk_app/ui/payment_summary.dart';
import 'package:kiosk_app/ui/product_list.dart';
import 'package:kiosk_app/ui/service_list.dart';
import 'package:kiosk_app/ui/till_balance_dialog.dart';
import '../services/database_service.dart';

class Transactions extends StatefulWidget {
  const Transactions({super.key});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  final TextEditingController _tipController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final database = DatabaseService.instance;
  late Future<List<Map<String, dynamic>>> _activeEmployeesFuture;
  late Future<List<Cuts>> cuttings;
  late Future<List<Product>> products;
  String get currentShopId => AppState.requireShopId();

  String? _selectedEmployeeId;
  Map<String, CartItem> _cartItems = {};

  double tip = 0;
  double discount = 0;
  @override
  void dispose() {
    _tipController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBalance();
    });

    _reloadActiveEmployees();
    _loadData();
  }

  Future<void> _checkBalance() async {
    final allowed = await TillBalanceDialog.checkAndShow(context);

    if (!mounted) return;

    if (!allowed) {
      Navigator.of(context).pop();
    }
  }

  void _loadData() {
    cuttings = database.getEPC(
      table: DatabaseService.tableCuts,
      fromMap: Cuts.fromMap,
    );

    products = database.getEPC(
      table: DatabaseService.tableProducts,
      fromMap: Product.fromMap,
    );
  }

  void _increment(String idKey, String name, double price) {
    setState(() {
      if (_cartItems.containsKey(idKey)) {
        _cartItems[idKey]!.quantity++;
      } else {
        _cartItems[idKey] = CartItem(
          idKey: idKey,
          name: name,
          unitPrice: price,
          quantity: 1,
        );
      }
    });
  }

  void _decrement(String idKey) {
    if (!_cartItems.containsKey(idKey)) return;

    setState(() {
      final item = _cartItems[idKey]!;
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cartItems.remove(idKey);
      }
    });
  }

  void _reloadActiveEmployees() {
    setState(() {
      _activeEmployeesFuture = database.getActiveEmployees();
    });
  }

  // Get the total of all items in the cart
  double get _baseTotal {
    return _cartItems.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Get the final total including tip and discount
  double get _finalTotal {
    return _baseTotal + tip - discount;
  }

  // In _TransactionsState
  Future<void> _saveTransaction(String paymentMethod) async {
    final headerObject = TransactionHeader(
      employeeId: _selectedEmployeeId!,
      baseTotal: _baseTotal,
      tip: tip,
      discount: discount,
      finalTotal: _finalTotal,
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      shopId: currentShopId,
    );

    final itemObjects = _cartItems.values.map((cartItem) {
      final itemType = cartItem.idKey.split('_')[0];
      return TransactionItem(
        itemType: itemType,
        itemName: cartItem.name,
        unitPrice: cartItem.unitPrice,
        quantity: cartItem.quantity,
        shopId: currentShopId,
      );
    }).toList();
    if (mounted) Navigator.pop(context);
    // 3. Call Database Service to Execute the Transaction
    try {
      // You will implement this in DatabaseService next!
      await database.saveTransactionObjects(headerObject, itemObjects);
      _tipController.clear();
      _discountController.clear();
      // 4. Reset State on Success

      setState(() {
        _selectedEmployeeId = null;
        _cartItems = {}; // Clear the cart
        tip = 0;
        discount = 0;
      });
      // Show success message
      if (mounted) {
        SyncService().syncTransactions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved successfully!')),
        );
      }
    } catch (e) {
      _showErrorDialog(
        'Transaction Failed',
        'The transaction could not be saved due to an unexpected error. Please try again.\n\nDetails: ${e.toString()}',
      );
    }
  }

  void _confirm(String method) {
    if (_selectedEmployeeId == null || _cartItems.isEmpty) {
      _showErrorDialog(
        'Missing Data',
        'Please select an active employee and add at least one item to the cart before confirming the transaction.',
      );
      return;
    }

    // 2. Business Validation: Check for Negative Total
    if (_finalTotal < 0) {
      _showErrorDialog(
        'Invalid Discount/Tip',
        'The final total cannot be negative. Please adjust the discount or tip. Current Total: \$${_finalTotal.toStringAsFixed(2)}',
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $method Payment"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Employee ID: $_selectedEmployeeId"),
              Text("Base Total: €${(_baseTotal).toStringAsFixed(2)}"),
              Text("Tip: €${tip.toStringAsFixed(2)}"),
              Text("Discount: €${discount.toStringAsFixed(2)}"),
              const Divider(),
              Text(
                "FINAL TOTAL: €${_finalTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          FilledButton(
            onPressed: () {
              _saveTransaction(method);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  // Inside the _TransactionsState class in transactions.dart

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: UniversalScaffold(
        title: "Transaction",

        body: LayoutBuilder(
          builder: (context, constraints) {
            const double tabletBreakpoint = 800; // Define your breakpoint

            if (constraints.maxWidth > tabletBreakpoint) {
              return _buildTabletLayout();
            } else {
              return _buildPhoneLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. EMPLOYEES
          EmployeeDropdown(
            activeEmployeesFuture: _activeEmployeesFuture,
            selectedEmployeeId: _selectedEmployeeId,
            onChanged: (val) {
              setState(() {
                _selectedEmployeeId = val;
              });
            },
            onRefresh: _reloadActiveEmployees,
          ),

          const SizedBox(height: 20),

          // 2. SERVICES
          SizedBox(
            height: screenHeight * 0.30,
            child: ServiceList(
              cutsFuture: cuttings,
              cartItems: _cartItems,
              onIncrement: _increment,
              onDecrement: _decrement,
            ),
          ),

          const SizedBox(height: 20),

          // 3. PRODUCTS
          SizedBox(
            height: screenHeight * 0.40,
            child: ProductList(
              productsFuture: products,
              cartItems: _cartItems,
              onIncrement: _increment,
              onDecrement: _decrement,
            ),
          ),

          const SizedBox(height: 20),

          // 4. TIP + DISCOUNT + PAYMENT
          PaymentSummary(
            tipController: _tipController,
            discountController: _discountController,
            baseTotal: _baseTotal,
            finalTotal: _finalTotal,
            onTipChanged: (value) {
              setState(() {
                tip = double.tryParse(value) ?? 0;
              });
            },
            onDiscountChanged: (value) {
              setState(() {
                discount = double.tryParse(value) ?? 0;
              });
            },
            onConfirmCash: () => _confirm("Cash"),
            onConfirmCard: () => _confirm("Card"),
          ),
        ],
      ),
    );
  }

  // 3. The Wide Screen Layout (Tablet/Horizontal)
  Widget _buildTabletLayout() {
    // Use a Row for the main split-screen layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === LEFT PANE: Employee Dropdown, Services, and Products ===
        Expanded(
          flex: 5, // Gives this pane 5/8 of the screen width (62.5%)
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. EMPLOYEES (On top, spanning the full width of the left pane)
                EmployeeDropdown(
                  activeEmployeesFuture: _activeEmployeesFuture,
                  selectedEmployeeId: _selectedEmployeeId,
                  onChanged: (val) {
                    setState(() {
                      _selectedEmployeeId = val;
                    });
                  },
                  onRefresh: _reloadActiveEmployees,
                ),

                const Divider(height: 20, thickness: 1),

                // 2. SERVICES AND PRODUCTS (Side-by-side in a Row)
                SizedBox(
                  // Use a fixed height for the scrollable list container
                  height: MediaQuery.of(context).size.height * 0.60,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Services (takes half the space)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: ServiceList(
                            cutsFuture: cuttings,
                            cartItems: _cartItems,
                            onIncrement: _increment,
                            onDecrement: _decrement,
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                      // Products (takes the other half)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: ProductList(
                            productsFuture: products,
                            cartItems: _cartItems,
                            onIncrement: _increment,
                            onDecrement: _decrement,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // A vertical divider for better visual separation
        const VerticalDivider(width: 1, thickness: 1),

        // === RIGHT PANE: Cart Summary and Payment Controls ===
        Expanded(
          flex: 3, // Gives this pane 3/8 of the screen width (37.5%)
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // **Cart Summary List (NEW UI COMPONENT NEEDED)**
                // Since you only listed the Tip/Discount/Payment section,
                // we'll assume this area will eventually hold a dedicated list
                // of the items in `_cartItems`. For now, let's put a placeholder
                // or expand the PaymentSummary to include the list view.

                // For a true tablet layout, you need to display what's IN the cart!
                const Text(
                  "Order Summary",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Use Expanded to make the cart list take up the available vertical space
                Expanded(
                  child: ListView(
                    children: _cartItems.values.map((item) {
                      // This uses your existing CartItem component for display
                      return ListTile(
                        title: Text(item.name),
                        trailing: Text(
                          '${item.quantity} x €${item.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Final Payment Section
                PaymentSummary(
                  tipController: _tipController,
                  discountController: _discountController,
                  baseTotal: _baseTotal,
                  finalTotal: _finalTotal,
                  onTipChanged: (value) {
                    setState(() {
                      tip = double.tryParse(value) ?? 0;
                    });
                  },
                  onDiscountChanged: (value) {
                    setState(() {
                      discount = double.tryParse(value) ?? 0;
                    });
                  },
                  onConfirmCash: () => _confirm("Cash"),
                  onConfirmCard: () => _confirm("Card"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
