class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value, {bool isSignUp = false}) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';

    // For login, many apps only require non-empty
    if (!isSignUp) return null;

    // For sign up, enforce stronger rules
    if (v.length < 8) return 'Password must be at least 8 characters';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasNumber = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasNumber) return 'Use Upper case and Lower case letters and numbers';
    return null;
  }
}
