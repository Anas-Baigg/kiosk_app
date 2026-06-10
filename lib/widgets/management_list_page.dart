import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kiosk_app/services/database_service.dart';
import 'package:kiosk_app/services/realtime_service.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:kiosk_app/widgets/gradient_scaffold.dart';

/// Holds all the specific configuration for the generic page.
/// This tells the page *what* to build and *how* to handle the data.
class ManagementPageConfig<T> {
  final String pageTitle;
  final String listTitle;
  final String itemName; // e.g., "Cut", "Product", "Employee"
  final String field1Label;
  final String field2Label;
  final String idColumn;

  final TextInputType field2KeyboardType;
  final IconData listIcon;

  // Database
  final String tableName;
  final String orderByColumn;

  // Data Handlers
  final T Function(Map<String, dynamic>) fromMap;
  final Map<String, dynamic> Function(T) toMap;
  final dynamic Function(T) getId;
  final String Function(T) getName;
  final String Function(T) getValueString;
  final String Function(T) getSubtitle;

  // Validation
  final String? Function(String?) validateField1;
  final String? Function(String?) validateField2;

  // Item Creation (from text fields)
  final T Function(String field1, String field2) createItem;
  final T Function(T originalItem, String field1, String field2) updateItem;
  final Future<void> Function()? onRefresh;
  final bool field2Obscure;
  final String? field2UpdateHint;
  ManagementPageConfig({
    required this.pageTitle,
    required this.listTitle,
    required this.itemName,
    required this.field1Label,
    required this.field2Label,
    this.field2KeyboardType = TextInputType.text,
    required this.listIcon,
    required this.tableName,
    required this.orderByColumn,
    required this.fromMap,
    required this.toMap,
    required this.getId,
    required this.getName,
    required this.getValueString,
    required this.getSubtitle,
    required this.validateField1,
    required this.validateField2,
    required this.createItem,
    required this.updateItem,
    required this.idColumn,
    this.onRefresh,
    this.field2Obscure = false,
    this.field2UpdateHint,
  });
}

/// A generic stateful widget for managing any data type
class GenericManagementPage<T> extends StatefulWidget {
  final ManagementPageConfig<T> config;
  const GenericManagementPage({super.key, required this.config});

  @override
  State<GenericManagementPage<T>> createState() =>
      _GenericManagementPageState<T>();
}

class _GenericManagementPageState<T> extends State<GenericManagementPage<T>> {
  final databs = DatabaseService.instance;
  List<T> items = [];
  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  bool _isRefreshing = false;
  String? _field1Error;
  String? _field2Error;
  // A helper getter to make accessing the config easier
  ManagementPageConfig<T> get config => widget.config;

  @override
  void initState() {
    super.initState();
    _loadItems();
    RealtimeService.instance.setOnChangeCallback((table) {
      if (table == widget.config.tableName && mounted) _loadItems();
    });
  }

  // Helper method to decide which sync to run
  void _triggerSync() {
    final table = widget.config.tableName;
    final sync = SyncService.instance;

    if (table == DatabaseService.tableEmployee) {
      sync.syncEmployees();
    } else if (table == DatabaseService.tableProducts) {
      sync.syncProducts();
    } else if (table == DatabaseService.tableCuts) {
      sync.syncCuts();
    }
  }

  Future<void> _handleRefresh() async {
    if (config.onRefresh == null) return;

    setState(() => _isRefreshing = true);
    try {
      await config.onRefresh!();
      await _loadItems();
      _showSnackBar("Data refreshed from cloud");
    } catch (e) {
      _showSnackBar("Refresh failed: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadItems() async {
    final list = await databs.getEPC<T>(
      table: config.tableName,
      fromMap: config.fromMap,
      orderBy: '${config.orderByColumn} COLLATE NOCASE',
      onlyActive: true,
    );
    setState(() => items = list);
  }

  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    RealtimeService.instance.clearOnChangeCallback();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearFieldErrors() {
    if (_field1Error != null || _field2Error != null) {
      setState(() {
        _field1Error = null;
        _field2Error = null;
      });
    }
  }

  Widget _buildAddForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          keyboardType: TextInputType.text,
          controller: _field1Controller,
          onChanged: (_) => _clearFieldErrors(),
          decoration: InputDecoration(
            label: Text(config.field1Label),
            errorText: _field1Error,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          keyboardType: config.field2KeyboardType,
          controller: _field2Controller,
          obscureText: config.field2Obscure,
          onChanged: (_) => _clearFieldErrors(),
          decoration: InputDecoration(
            label: Text(config.field2Label),
            errorText: _field2Error,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF101418),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text("Save", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _addItem() async {
    final f1Value = _field1Controller.text.trim().toUpperCase();
    final f2Value = _field2Controller.text.trim().replaceAll(',', '.');

    final f1Err = config.validateField1(f1Value);
    final f2Err = config.validateField2(f2Value);

    if (f1Err != null || f2Err != null) {
      setState(() {
        _field1Error = f1Err;
        _field2Error = f2Err;
      });
      return;
    }

    setState(() {
      _field1Error = null;
      _field2Error = null;
    });

    final newItem = config.createItem(f1Value, f2Value);
    try {
      await databs.addEPC(table: config.tableName, data: config.toMap(newItem));
      _triggerSync();
      _field1Controller.clear();
      _field2Controller.clear();
      await _loadItems();
      _showSnackBar('${config.itemName} saved');
    } catch (e) {
      final msg = e.toString().replaceFirst("Exception: ", "");
      _showSnackBar(msg);
    }
  }

  Future<void> _showUpdateDialog(T item) async {
    final f1UpdateController = TextEditingController(
      text: config.getName(item),
    );
    final f2UpdateController = TextEditingController(
      text: config.field2Obscure ? '' : config.getValueString(item),
    );
    final itemId = config.getId(item);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        String? f1Error;
        String? f2Error;
        bool success = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Center(
                child: Text(
                  "Update ${config.itemName}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                    fontSize: 20,
                  ),
                ),
              ),
              content: success
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 70),
                        SizedBox(height: 10),
                        Text(
                          "Saved!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: f1UpdateController,
                            onChanged: (_) {
                              if (f1Error != null) {
                                setDialogState(() => f1Error = null);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: config.field1Label,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              errorText: f1Error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: f2UpdateController,
                            keyboardType: config.field2KeyboardType,
                            obscureText: config.field2Obscure,
                            onChanged: (_) {
                              if (f2Error != null) {
                                setDialogState(() => f2Error = null);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: config.field2Label,
                              hintText: config.field2UpdateHint,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              errorText: f2Error,
                            ),
                          ),
                        ],
                      ),
                    ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: success
                  ? []
                  : [
                      FilledButton.tonal(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () async {
                          final newF1 =
                              f1UpdateController.text.trim().toUpperCase();
                          final f2Raw = f2UpdateController.text
                              .trim()
                              .replaceAll(',', '.');
                          final keepOriginalF2 =
                              f2Raw.isEmpty && config.field2Obscure;
                          final newF2 = keepOriginalF2
                              ? config.getValueString(item)
                              : f2Raw;

                          final f1Err = config.validateField1(newF1);
                          final f2Err = keepOriginalF2
                              ? null
                              : config.validateField2(newF2);

                          if (f1Err != null || f2Err != null) {
                            setDialogState(() {
                              f1Error = f1Err;
                              f2Error = f2Err;
                            });
                            return;
                          }

                          final updatedItem =
                              config.updateItem(item, newF1, newF2);
                          await databs.updateEPC(
                            table: config.tableName,
                            data: config.toMap(updatedItem),
                            id: itemId,
                          );
                          _triggerSync();
                          await _loadItems();
                          if (!mounted) return;
                          setDialogState(() => success = true);
                          await Future.delayed(const Duration(seconds: 1));
                          if (context.mounted) Navigator.pop(dialogContext);
                        },
                        child: const Text(
                          "Update",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(T item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${config.itemName}'),
        content: Text(
          'Are you sure you want to delete "${config.getName(item)}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF55045),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final itemId = config.getId(item);
    await databs.deactivateEPC(
      table: config.tableName,
      idColumn: config.idColumn,
      id: itemId,
    );
    _triggerSync();
    await _loadItems();
    _showSnackBar('${config.itemName} deleted');
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final maxContentWidth = 600.0; // keeps inputs readable on wide screens

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: UniversalScaffold(
        title: config.pageTitle,
        actions: [
          if (config.onRefresh != null)
            _isRefreshing
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
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
                    icon: const Icon(Icons.refresh),
                    onPressed: _handleRefresh,
                  ),
        ],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: form
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: SingleChildScrollView(
                              child: _buildAddForm(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // RIGHT: list
                      Expanded(flex: 7, child: _buildList()),
                    ],
                  )
                : // PORTRAIT: your original vertical flow
                  Column(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: _buildAddForm(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            config.listTitle,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildList()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: SlidableAutoCloseBehavior(
            closeWhenOpened: true,
            child: Slidable(
              startActionPane: ActionPane(
                motion: const StretchMotion(),
                children: [
                  SlidableAction(
                    backgroundColor: Colors.indigoAccent,
                    icon: Icons.update,
                    label: "Update",
                    onPressed: (context) => _showUpdateDialog(item),
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                children: [
                  SlidableAction(
                    backgroundColor: const Color(0xFFF55045),
                    icon: Icons.delete,
                    label: "Delete",
                    onPressed: (context) => _confirmDelete(item),
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(config.listIcon),
                title: Text(config.getName(item).toUpperCase()),
                subtitle: Text(config.getSubtitle(item)),
                tileColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
