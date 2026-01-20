import 'package:flutter/material.dart';
import 'package:kiosk_app/services/home_tile.dart';
import 'package:kiosk_app/ui/gradient_scaffold.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 2,
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
                MaterialPageRoute(builder: (context) => const AddCuts()),
              ),
              icon: Icons.content_cut,
              label: "ADD CUTS",
            ),
            HomeTileButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProducts()),
              ),
              icon: Icons.add_shopping_cart,
              label: "ADD PRODUCTS",
            ),
            HomeTileButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsPage()),
              ),
              icon: Icons.bar_chart,
              label: "REPORTS",
            ),
          ],
        ),
      ),
    );
  }
}
