import 'package:flutter/material.dart';
import 'package:kiosk_app/models/cart_item.dart';
import 'package:kiosk_app/models/cuts.dart';
import 'package:kiosk_app/models/products.dart';
import 'package:kiosk_app/models/transaction_item.dart';
import 'package:kiosk_app/models/transaction_model.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/database/database_service.dart';
import 'package:kiosk_app/services/database/repositories/time_log_repository.dart';
import 'package:kiosk_app/services/database/repositories/transaction_repository.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:kiosk_app/widgets/employee_dropdown.dart';
import 'package:kiosk_app/widgets/gradient_scaffold.dart';
import 'package:kiosk_app/widgets/payment_summary.dart';
import 'package:kiosk_app/widgets/product_list.dart';
import 'package:kiosk_app/widgets/service_list.dart';
import 'package:kiosk_app/widgets/till_balance_dialog.dart';

class Transactions extends StatefulWidget {
  const Transactions({super.key});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  final TextEditingController _tipController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final _db = DatabaseService.instance;
  final _timeLogRepo = TimeLogRepository(DatabaseService.instance);
  final _txRepo = TransactionRepository(DatabaseService.instance);
  late Future<List<Map<String, dynamic>>> _activeEmployeesFuture;
  late Future<List<Cuts>> cuttings;
  late Future<List<Product>> products;
  String get currentShopId => AppState.requireShopId();

  String? _selectedEmployeeId;
  late final ValueNotifier<Map<String, CartItem>> _cartNotifier;

  double tip = 0;
  double discount = 0;
  @override
  void dispose() {
    _tipController.dispose();
    _discountController.dispose();
    _cartNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cartNotifier = ValueNotifier({});

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
    cuttings = _db.getEPC(
      table: DatabaseService.tableCuts,
      fromMap: Cuts.fromMap,
    );

    products = _db.getEPC(
      table: DatabaseService.tableProducts,
      fromMap: Product.fromMap,
    );
  }

  void _increment(String idKey, String name, double price) {
    final updated = Map<String, CartItem>.from(_cartNotifier.value);
    if (updated.containsKey(idKey)) {
      updated[idKey]!.increment();
    } else {
      updated[idKey] = CartItem(idKey: idKey, name: name, unitPrice: price);
    }
    _cartNotifier.value = updated;
  }

  void _decrement(String idKey) {
    if (!_cartNotifier.value.containsKey(idKey)) return;
    final updated = Map<String, CartItem>.from(_cartNotifier.value);
    final item = updated[idKey]!;
    if (item.quantity > 1) {
      item.decrement();
    } else {
      updated.remove(idKey);
    }
    _cartNotifier.value = updated;
  }

  void _reloadActiveEmployees() {
    setState(() {
      _activeEmployeesFuture = _timeLogRepo.getActiveEmployees();
    });
  }

  // Get the total of all items in the cart
  double get _baseTotal {
    return _cartNotifier.value.values.fold(0.0, (sum, item) => sum + item.subtotal);
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

    final itemObjects = _cartNotifier.value.values.map((cartItem) {
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
    try {
      await _txRepo.saveTransactionObjects(headerObject, itemObjects);
      _tipController.clear();
      _discountController.clear();
      if (!mounted) return;
      _cartNotifier.value = {};
      setState(() {
        _selectedEmployeeId = null;
        tip = 0;
        discount = 0;
      });
      final syncService = SyncService.instance;
      syncService.syncTransactions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully!')),
      );
    } catch (e) {
      _showErrorDialog(
        'Transaction Failed',
        'The transaction could not be saved due to an unexpected error. Please try again.\n\nDetails: ${e.toString()}',
      );
    }
  }

  void _confirm(String method) {
    if (_selectedEmployeeId == null || _cartNotifier.value.isEmpty) {
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
    return SafeArea(
      child: SingleChildScrollView(
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
              child: ValueListenableBuilder<Map<String, CartItem>>(
                valueListenable: _cartNotifier,
                builder: (context, cart, _) {
                  return ServiceList(
                    cutsFuture: cuttings,
                    cartItems: cart,
                    onIncrement: _increment,
                    onDecrement: _decrement,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 3. PRODUCTS
            SizedBox(
              height: screenHeight * 0.40,
              child: ValueListenableBuilder<Map<String, CartItem>>(
                valueListenable: _cartNotifier,
                builder: (context, cart, _) {
                  return ProductList(
                    productsFuture: products,
                    cartItems: cart,
                    onIncrement: _increment,
                    onDecrement: _decrement,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 4. TIP + DISCOUNT + PAYMENT
            ValueListenableBuilder<Map<String, CartItem>>(
              valueListenable: _cartNotifier,
              builder: (context, cart, _) {
                final base = cart.values.fold(0.0, (sum, item) => sum + item.subtotal);
                return PaymentSummary(
                  tipController: _tipController,
                  discountController: _discountController,
                  baseTotal: base,
                  finalTotal: base + tip - discount,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3. The Wide Screen Layout (Tablet/Horizontal)
  Widget _buildTabletLayout() {
    // Use a Row for the main split-screen layout
    return SafeArea(
      child: Row(
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
                ValueListenableBuilder<Map<String, CartItem>>(
                  valueListenable: _cartNotifier,
                  builder: (context, cart, _) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.60,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: ServiceList(
                                cutsFuture: cuttings,
                                cartItems: cart,
                                onIncrement: _increment,
                                onDecrement: _decrement,
                              ),
                            ),
                          ),
                          const VerticalDivider(width: 1, thickness: 1),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: ProductList(
                                productsFuture: products,
                                cartItems: cart,
                                onIncrement: _increment,
                                onDecrement: _decrement,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
            child: ValueListenableBuilder<Map<String, CartItem>>(
              valueListenable: _cartNotifier,
              builder: (context, cart, _) {
                final base = cart.values.fold(0.0, (sum, item) => sum + item.subtotal);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Order Summary",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: cart.values.map((item) {
                          return ListTile(
                            title: Text(item.name),
                            trailing: Text(
                              '${item.quantity} x €${item.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    PaymentSummary(
                      tipController: _tipController,
                      discountController: _discountController,
                      baseTotal: base,
                      finalTotal: base + tip - discount,
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
                );
              },
            ),
          ),
        ),
      ],
    ),
    );
  }
}
