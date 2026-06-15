import 'dart:async';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_app/screens/app_state.dart';
import 'package:kiosk_app/utils/app_theme.dart';
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
      backgroundColor: AppColors.surfaceHigh,
      scrollable: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      title: Text(
        'Admin Access',
        style: AppTextStyles.titleMd().copyWith(color: AppColors.primary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please enter the 5-digit Admin Password',
            style: AppTextStyles.bodySm(),
          ),
          const SizedBox(height: 16),
          Text('PASSWORD', style: AppTextStyles.labelCaps()),
          const SizedBox(height: 6),
          TextField(
            controller: _passController,
            obscureText: true,
            keyboardType: TextInputType.number,
            autofocus: true,
            enabled: !_lockedOut,
            style: AppTextStyles.bodyLg(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              hintText: 'Enter Password',
              errorText: _lockedOut ? null : _errorText,
            ),
            onSubmitted: _lockedOut ? null : (_) => _handleVerify(),
          ),
          if (_lockedOut) ...[
            const SizedBox(height: 12),
            Text(
              'Too many failed attempts.\nTry again in $_countdown seconds.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm().copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.outlineVariant),
            foregroundColor: AppColors.onSurface,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _lockedOut ? null : _handleVerify,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
