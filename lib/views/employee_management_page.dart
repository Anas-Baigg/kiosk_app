import 'package:flutter/material.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/services/download_service.dart';
import 'package:kiosk_app/ui/management_list_page.dart';
import 'package:uuid/uuid.dart';
import 'package:kiosk_app/components/employees.dart';
import 'package:kiosk_app/services/employee_validators.dart';
import 'package:kiosk_app/services/database_service.dart';

class AddWorker extends StatelessWidget {
  const AddWorker({super.key});
  String get currentShopId => AppState.requireShopId();

  @override
  Widget build(BuildContext context) {
    // 1. Define the configuration for "Employees"
    final employeeConfig = ManagementPageConfig<Employees>(
      pageTitle: "Add Employees",
      listTitle: "Employees",
      itemName: "Employee",
      field1Label: "Employee Name",
      field2Label: "Employee Code",
      field2KeyboardType: TextInputType.number,
      listIcon: Icons.person,
      tableName: DatabaseService.tableEmployee,
      orderByColumn: DatabaseService.colName,
      idColumn: DatabaseService.colEmployeeId,

      // Data Handlers
      fromMap: (map) => Employees.fromMap(map),
      toMap: (emp) => emp.toMap(),
      getId: (emp) => emp.id,
      getName: (emp) => emp.name,
      getValueString: (emp) => emp.passcode.toString(),
      getSubtitle: (emp) => "Passcode: ${emp.passcode}",
      onRefresh: () => PullService().downloadEmployees(),
      // Validation
      validateField1: EmployeeValidators.validateName,
      validateField2: EmployeeValidators.validatePasscode,

      // Creation
      createItem: (name, code) {
        final uuid = const Uuid();
        return Employees(
          id: uuid.v4(),
          name: name,
          passcode: int.parse(code),
          createdAt: DateTime.now(),
          shopId: currentShopId,
        );
      },
      updateItem: (originalEmployee, name, code) => Employees(
        id: originalEmployee.id,
        shopId: originalEmployee.shopId,
        createdAt: originalEmployee.createdAt,
        name: name,
        passcode: int.parse(code),
        isActive: originalEmployee.isActive,
      ),
    );

    // 2. Return the generic page with the config
    return GenericManagementPage<Employees>(config: employeeConfig);
  }
}
