import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kiosk_app/services/database_service.dart';
import 'package:kiosk_app/services/realtime_service.dart';
import 'package:kiosk_app/services/sync_service.dart';
import 'package:kiosk_app/utils/app_theme.dart';
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
  bool _isRefreshing = false;
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
    RealtimeService.instance.clearOnChangeCallback();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Unified add / edit dialog in the dark amber system.
  /// Passing [existing] = null opens the dialog in "add" mode.
  Future<void> _showItemDialog({T? existing}) async {
    final isEdit = existing != null;
    final f1Ctrl = TextEditingController(
      text: isEdit ? config.getName(existing) : '',
    );
    final f2Ctrl = TextEditingController(
      text: isEdit && !config.field2Obscure
          ? config.getValueString(existing)
          : '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        String? f1Error;
        String? f2Error;
        bool success = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget label(String text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(text, style: AppTextStyles.labelCaps()),
            );

            return AlertDialog(
              backgroundColor: AppColors.surfaceHigh,
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              title: Center(
                child: Text(
                  isEdit
                      ? "Update ${config.itemName}"
                      : "New ${config.itemName}",
                  style: AppTextStyles.titleMd().copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              content: success
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 70,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Saved!",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLg().copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label(config.field1Label.toUpperCase()),
                        TextField(
                          controller: f1Ctrl,
                          style: AppTextStyles.bodyLg(),
                          onChanged: (_) {
                            if (f1Error != null) {
                              setDialogState(() => f1Error = null);
                            }
                          },
                          decoration: InputDecoration(errorText: f1Error),
                        ),
                        const SizedBox(height: 16),
                        label(config.field2Label.toUpperCase()),
                        TextField(
                          controller: f2Ctrl,
                          keyboardType: config.field2KeyboardType,
                          obscureText: config.field2Obscure,
                          style: AppTextStyles.bodyLg(),
                          onChanged: (_) {
                            if (f2Error != null) {
                              setDialogState(() => f2Error = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: isEdit ? config.field2UpdateHint : null,
                            errorText: f2Error,
                          ),
                        ),
                      ],
                    ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: success
                  ? []
                  : [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.outlineVariant,
                          ),
                          foregroundColor: AppColors.onSurface,
                        ),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final newF1 = f1Ctrl.text.trim().toUpperCase();
                          final f2Raw = f2Ctrl.text.trim().replaceAll(',', '.');
                          final keepOriginalF2 =
                              isEdit && f2Raw.isEmpty && config.field2Obscure;
                          final newF2 = keepOriginalF2
                              ? config.getValueString(existing)
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

                          try {
                            if (isEdit) {
                              final updated =
                                  config.updateItem(existing, newF1, newF2);
                              await databs.updateEPC(
                                table: config.tableName,
                                data: config.toMap(updated),
                                id: config.getId(existing),
                              );
                            } else {
                              final created = config.createItem(newF1, newF2);
                              await databs.addEPC(
                                table: config.tableName,
                                data: config.toMap(created),
                              );
                            }
                          } catch (e) {
                            final msg =
                                e.toString().replaceFirst("Exception: ", "");
                            setDialogState(() => f2Error = msg);
                            return;
                          }

                          _triggerSync();
                          await _loadItems();
                          if (!mounted) return;
                          setDialogState(() => success = true);
                          await Future.delayed(const Duration(seconds: 1));
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: Text(isEdit ? "Update" : "Save"),
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
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        title: Text(
          'Delete ${config.itemName}',
          style: AppTextStyles.titleMd().copyWith(color: AppColors.error),
        ),
        content: Text(
          'Are you sure you want to delete "${config.getName(item)}"? This cannot be undone.',
          style: AppTextStyles.bodySm(),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.outlineVariant),
              foregroundColor: AppColors.onSurface,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: UniversalScaffold(
        title: config.pageTitle,
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          onPressed: () => _showItemDialog(),
          child: const Icon(Icons.add),
        ),
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
                          color: AppColors.primary,
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    config.listTitle.toUpperCase(),
                    style: AppTextStyles.labelCaps(),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            "No ${config.listTitle.toLowerCase()} yet.\nTap + to add one.",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySm(),
                          ),
                        )
                      : _buildList(),
                ),
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
        final name = config.getName(item);
        final trailingText = config.field2Obscure
            ? '•••••'
            : config.getSubtitle(item);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SlidableAutoCloseBehavior(
            closeWhenOpened: true,
            child: Slidable(
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.28,
                children: [
                  SlidableAction(
                    backgroundColor: AppColors.errorContainer,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: "Delete",
                    borderRadius: BorderRadius.circular(12),
                    onPressed: (_) => _confirmDelete(item),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showItemDialog(existing: item),
                onLongPress: () => _confirmDelete(item),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _Avatar(name: name),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          name.toUpperCase(),
                          style: AppTextStyles.titleMd(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trailingText,
                        style: AppTextStyles.labelCaps().copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Circular initials avatar — amber background, dark text.
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: AppTextStyles.labelCaps().copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
