import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../ui/employee_dropdown.dart';
import '../ui/gradient_scaffold.dart';

class CheckTip extends StatefulWidget {
  const CheckTip({super.key});

  @override
  State<CheckTip> createState() => _CheckTipState();
}

class _CheckTipState extends State<CheckTip> {
  late Future<List<Map<String, dynamic>>> _activeEmployeesFuture;
  final database = DatabaseService.instance;

  String? _selectedEmployeeId;
  final TextEditingController _passcodeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Map<String, double>? _tipResults;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  void _load() {
    _activeEmployeesFuture = database.getAllActiveEmployees();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tipResults = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _checkTips() async {
    setState(() {
      _errorMessage = null;
      _tipResults = null;
    });

    if (_selectedEmployeeId == null) {
      setState(() => _errorMessage = "Please select your name.");
      return;
    }

    if (_passcodeController.text.isEmpty) {
      setState(() => _errorMessage = "Please enter your passcode.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final validEmployeeId = await database.getEmployeeIdByPasscode(
        _passcodeController.text,
      );

      if (validEmployeeId != _selectedEmployeeId) {
        setState(() {
          _errorMessage = "Invalid passcode. Please try again.";
          _isLoading = false;
        });
        return;
      }

      final results = await database.getEmployeeTipsForDate(
        _selectedEmployeeId!,
        _selectedDate,
      );

      setState(() {
        _tipResults = results;
        _passcodeController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred while checking tips.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: UniversalScaffold(
        title: "Check Tips",
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Check Your Daily Tips",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          /// Employee Dropdown
                          EmployeeDropdown(
                            activeEmployeesFuture: _activeEmployeesFuture,
                            selectedEmployeeId: _selectedEmployeeId,
                            onChanged: (val) {
                              setState(() {
                                _selectedEmployeeId = val;
                                _tipResults = null;
                              });
                            },
                            onRefresh: _load,
                          ),
                          const SizedBox(height: 16),

                          /// Date Picker
                          ListTile(
                            title: const Text("Select Date"),
                            subtitle: Text(
                              DateFormat(
                                'EEEE, MMM d, yyyy',
                              ).format(_selectedDate),
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            tileColor: Colors.grey.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: () => _pickDate(context),
                          ),
                          const SizedBox(height: 16),

                          /// Passcode
                          TextField(
                            controller: _passcodeController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Enter Passcode",
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          /// Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _checkTips,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Check Tips",
                                      style: TextStyle(fontSize: 18),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          /// Error
                          if (_errorMessage != null)
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                          /// Results
                          if (_tipResults != null) ...[
                            const Divider(height: 40, thickness: 2),
                            Text(
                              "Tips for ${DateFormat('MMM d').format(_selectedDate)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _buildResponsiveTipCards(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveTipCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildTipCard(
                "Card Tips",
                _tipResults!['Card']!,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTipCard(
                "Cash Tips",
                _tipResults!['Cash']!,
                Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "€ ${amount.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
