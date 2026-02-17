import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/views/admin_page.dart';

class AdminAuthService {
  static void showAdminAccessDialog(BuildContext context) {
    final TextEditingController passController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Admin Access',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the 5-digit Admin Password'),
              const SizedBox(height: 16),
              TextFormField(
                controller: passController,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';

                  final storedHash = AppState.adminPasswordHash;
                  if (storedHash == null || storedHash.isEmpty) {
                    return 'System Error: No password set';
                  }
                  final isCorrect = BCrypt.checkpw(value, storedHash);

                  if (!isCorrect) {
                    return 'Incorrect Password';
                  }
                  return null;
                },
                onFieldSubmitted: (_) =>
                    _handleVerify(context, formKey, passController),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _handleVerify(context, formKey, passController),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _handleVerify(
    BuildContext context,
    GlobalKey<FormState> key,
    TextEditingController controller,
  ) {
    if (key.currentState?.validate() ?? false) {
      Navigator.pop(context); // Close dialog
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminPage()),
      );
    }
  }
}
