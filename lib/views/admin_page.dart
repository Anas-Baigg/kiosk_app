import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/utils/app_constants.dart';
import 'package:kiosk_app/utils/app_theme.dart';
import 'package:kiosk_app/widgets/home_tile.dart';
import 'package:kiosk_app/widgets/gradient_scaffold.dart';
import 'package:kiosk_app/views/cuts_management_page.dart';
import 'package:kiosk_app/views/employee_management_page.dart';
import 'package:kiosk_app/views/products_management_page.dart';
import 'package:kiosk_app/views/report.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;
    return UniversalScaffold(
      title: "ADMIN PANEL",
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.4,
                  children: [
                    HomeTileButton(
                      icon: Icons.person_add_alt,
                      label: "ADD EMPLOYEE",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddWorker()),
                        );
                      },
                    ),
                    HomeTileButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCuts(),
                        ),
                      ),
                      icon: Icons.content_cut,
                      label: "ADD CUTS",
                    ),
                    HomeTileButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProducts(),
                        ),
                      ),
                      icon: Icons.add_shopping_cart,
                      label: "ADD PRODUCTS",
                    ),
                    HomeTileButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsPage(),
                        ),
                      ),
                      icon: Icons.bar_chart,
                      label: "REPORTS",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Expanded(
          child: _statusCard(
            leading: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            label: "SYNC STATUS",
            value: "Local DB Active",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statusCard(
            leading: const Icon(
              Icons.update,
              size: 18,
              color: AppColors.outlineVariant,
            ),
            label: "LAST SYNC",
            value: "On change",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statusCard(
            leading: const Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.outlineVariant,
            ),
            label: "VERSION",
            value: "${AppConstants.appName} v1.0",
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required Widget leading,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.labelCaps()),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySm(),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
