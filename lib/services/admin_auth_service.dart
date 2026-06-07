import 'dart:async';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/views/admin_page.dart';

class AdminAuthService {
  static void showAdminAccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AdminAuthDialog(),
    );
  }
}

class _AdminAuthDialog extends StatefulWidget {
  const _AdminAuthDialog();

  @override
  State<_AdminAuthDialog> createState() => _AdminAuthDialogState();
}

class _AdminAuthDialogState extends State<_AdminAuthDialog> {
  final _passController = TextEditingController();

  int _attempts = 0;
  static const int _maxAttempts = 3;
  static const int _lockoutSeconds = 60;

  bool _lockedOut = false;
  int _countdown = 0;
  Timer? _timer;
  String? _errorText;

  @override
  void dispose() {
    _passController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startLockout() {
    setState(() {
      _lockedOut = true;
      _countdown = _lockoutSeconds;
      _errorText = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          t.cancel();
          _lockedOut = false;
          _attempts = 0;
        }
      });
    });
  }

  void _handleVerify() {
    final value = _passController.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'Required');
      return;
    }
    final storedHash = AppState.adminPasswordHash;
    if (storedHash == null || storedHash.isEmpty) {
      setState(() => _errorText = 'System Error: No password set');
      return;
    }
    if (BCrypt.checkpw(value, storedHash)) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminPage()),
      );
      return;
    }
    _attempts++;
    if (_attempts >= _maxAttempts) {
      _startLockout();
    } else {
      final remaining = _maxAttempts - _attempts;
      setState(() {
        _errorText =
            'Incorrect Password ($remaining ${remaining == 1 ? 'attempt' : 'attempts'} left)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Admin Access',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please enter the 5-digit Admin Password'),
          const SizedBox(height: 16),
          TextField(
            controller: _passController,
            obscureText: true,
            keyboardType: TextInputType.number,
            autofocus: true,
            enabled: !_lockedOut,
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
              errorText: _lockedOut ? null : _errorText,
            ),
            onSubmitted: _lockedOut ? null : (_) => _handleVerify(),
          ),
          if (_lockedOut) ...[
            const SizedBox(height: 12),
            Text(
              'Too many failed attempts.\nTry again in $_countdown seconds.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _lockedOut ? null : _handleVerify,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text('Verify', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
