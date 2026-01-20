import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiosk_app/components/dailyfinance.dart';
import 'package:kiosk_app/components/till_balance.dart';
import 'package:kiosk_app/components/time_log_entry.dart';
import 'package:kiosk_app/components/transactionModel.dart';
import 'package:kiosk_app/services/database_service.dart';
import 'package:kiosk_app/services/download_service.dart';
import 'package:kiosk_app/ui/date_range_picker.dart';
import 'package:kiosk_app/ui/financial_report_card.dart';
import 'package:kiosk_app/ui/gradient_scaffold.dart';
import 'package:kiosk_app/ui/time_logs.dart';
import 'package:kiosk_app/ui/transaction_list_widget.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final TextEditingController _dateControllerFrom = TextEditingController();
  final TextEditingController _dateControllerTo = TextEditingController();
  final database = DatabaseService.instance;
  late Future<List<TransactionHeader>> _transactions;
  late Future<List<TimeLogEntry>> _timeLogs;
  late Future<List<TillBalance>> _tillbalance;
  List<DailyFinance> _dailyFinance = [];

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  DateTime? _pickedFrom;
  DateTime? _pickedTo;

  int _totalTransactions = 0;
  double _totalCash = 0;
  double _totalCard = 0;
  Map<String, double> _tipsPerEmployee = {};
  @override
  void initState() {
    super.initState();
    _todayDate();
  }

  List<DailyFinance> buildDailyFinance({
    required List<TransactionHeader> transactions,
    required List<TillBalance> tillBalances,
  }) {
    final Map<DateTime, List<TransactionHeader>> txByDate = {};

    for (final tx in transactions) {
      final date = DateTime(
        tx.timestamp.year,
        tx.timestamp.month,
        tx.timestamp.day,
      );

      txByDate.putIfAbsent(date, () => []);
      txByDate[date]!.add(tx);
    }

    //  Index till balances by date
    final Map<DateTime, TillBalance> tillByDate = {
      for (final t in tillBalances)
        DateTime(t.balanceDate.year, t.balanceDate.month, t.balanceDate.day): t,
    };

    // Build daily finance rows
    final List<DailyFinance> result = [];

    for (final entry in txByDate.entries) {
      final date = entry.key;
      final dayTxs = entry.value;

      double cash = 0;
      double card = 0;

      for (final tx in dayTxs) {
        if (tx.paymentMethod.toUpperCase() == 'CASH') {
          cash += tx.finalTotal;
        } else if (tx.paymentMethod.toUpperCase() == 'CARD') {
          card += tx.finalTotal;
        }
      }

      final till = tillByDate[date]?.balanceAmount ?? 0;

      result.add(
        DailyFinance(
          date: date,
          cashTotal: cash,
          cardTotal: card,
          tillBalance: till,
        ),
      );
    }

    // Sort by date
    result.sort((a, b) => a.date.compareTo(b.date));

    return result;
  }

  Future<void> _selectDateFrom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickedFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    setState(() {
      _pickedFrom = date;
      _dateControllerFrom.text = DateFormat('yyyy-MM-dd').format(date);
    });
  }

  Future<void> _selectDateTo() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickedTo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    setState(() {
      _pickedTo = date;
      _dateControllerTo.text = DateFormat('yyyy-MM-dd').format(date);
    });
  }

  void _todayDate() {
    final date = DateTime.now();
    setState(() {
      _pickedFrom = date;
      _pickedTo = date;
      _dateControllerFrom.text = DateFormat('yyyy-MM-dd').format(date);
      _dateControllerTo.text = DateFormat('yyyy-MM-dd').format(date);
    });
    _runSearch();
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

  void _buildSummary(List<TransactionHeader> txs) {
    final totalTransactions = txs.length;
    double totalCash = 0;
    double totalCard = 0;
    final Map<String, double> tipsPerEmployee = {};

    for (final tx in txs) {
      if (tx.paymentMethod.toUpperCase() == 'CASH') {
        totalCash += tx.finalTotal;
      } else if (tx.paymentMethod.toUpperCase() == 'CARD') {
        totalCard += tx.finalTotal;
      }
      final name = tx.employeeName ?? 'Unknown';

      tipsPerEmployee[name] = (tipsPerEmployee[name] ?? 0) + tx.tip;
    }

    setState(() {
      _totalTransactions = totalTransactions;
      _totalCash = totalCash;
      _totalCard = totalCard;
      _tipsPerEmployee = tipsPerEmployee;
    });
  }

  Future<void> _runSearch() async {
    if (_pickedFrom == null || _pickedTo == null) {
      setState(() {
        _errorMessage = 'Please choose both FROM and TO dates.';
      });
      return _showErrorDialog("Error", _errorMessage!);
    }

    if (_pickedFrom!.isAfter(_pickedTo!)) {
      setState(() {
        _errorMessage = '"DATE FROM" cannot be after "DATE TO".';
      });
      return _showErrorDialog("Error", _errorMessage!);
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _timeLogs = database.getTimeLogsBetweenDates(
        from: _pickedFrom!,
        to: _pickedTo!,
      );
      _transactions = database.getTransactionsBetweenDates(
        from: _pickedFrom!,
        to: _pickedTo!,
      );
      _tillbalance = database.getBalanceBetweenDates(
        from: _pickedFrom!,
        to: _pickedTo!,
      );
    });

    try {
      final txs = await _transactions;
      final tillBalances = await _tillbalance;

      _buildSummary(txs);

      //  Build daily finance
      final dailyFinance = buildDailyFinance(
        transactions: txs,
        tillBalances: tillBalances,
      );

      setState(() {
        _dailyFinance = dailyFinance;
      });

      await _timeLogs;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncReports() async {
    setState(() => _isSyncing = true);
    try {
      // This calls your PullService to get fresh history (Transactions & Logs)
      await PullService().downloadRecentHistory(historyDays: 60);

      await _runSearch();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reports updated from cloud')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sync: $e')));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  void dispose() {
    _dateControllerFrom.dispose();
    _dateControllerTo.dispose();
    super.dispose();
  }

  Widget _buildWideLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align widgets to the top
        children: [
          // LEFT COLUMN: Date Picker and Time Logs (approx. 40% width)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DateRangePicker(
                  dateControllerFrom: _dateControllerFrom,
                  dateControllerTo: _dateControllerTo,
                  onSelectDateFrom: _selectDateFrom,
                  onSelectDateTo: _selectDateTo,
                  onTodayPressed: _todayDate,
                  onSearchPressed: _runSearch,
                ),
                const Divider(height: 20, thickness: 1),

                Expanded(
                  child: FinancialReportCard(
                    totalTransactions: _totalTransactions,
                    totalCash: _totalCash,
                    totalCard: _totalCard,
                    tipsPerEmployee: _tipsPerEmployee,
                    dailyFinance: _dailyFinance,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20), // Spacer between columns
          // RIGHT COLUMN: Summary and Transactions (approx. 60% width)
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TimeLogs(timeLogs: _timeLogs, database: database),
                ),

                const Divider(height: 20, thickness: 1),
                Expanded(
                  child: TransactionListWidget(
                    transactionsFuture: _transactions,
                    database: database,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NARROW LAYOUT BUILDER (EXISTING PHONE LAYOUT) ---
  Widget _buildNarrowLayout(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateRangePicker(
            dateControllerFrom: _dateControllerFrom,
            dateControllerTo: _dateControllerTo,
            onSelectDateFrom: _selectDateFrom,
            onSelectDateTo: _selectDateTo,
            onTodayPressed: _todayDate,
            onSearchPressed: _runSearch,
          ),

          const Divider(),

          FinancialReportCard(
            totalTransactions: _totalTransactions,
            totalCash: _totalCash,
            totalCard: _totalCard,
            tipsPerEmployee: _tipsPerEmployee,
            dailyFinance: _dailyFinance,
          ),
          const Divider(),
          SizedBox(
            height: screenHeight * 0.30,
            child: TimeLogs(timeLogs: _timeLogs, database: database),
          ),

          const Divider(),

          SizedBox(
            height: screenHeight * 0.40,
            child: TransactionListWidget(
              transactionsFuture: _transactions,
              database: database,
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    const double tabletBreakpoint = 800;

    return UniversalScaffold(
      title: 'Transaction Reports',
      actions: [
        _isSyncing
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : IconButton(
                tooltip: 'Sync from Cloud',
                icon: const Icon(Icons.cloud_download),
                onPressed: _syncReports,
              ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_errorMessage != null) {
            return Center(
              child: Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (constraints.maxWidth > tabletBreakpoint) {
            return _buildWideLayout(context);
          } else {
            return _buildNarrowLayout(context);
          }
        },
      ),
    );
  }
}
