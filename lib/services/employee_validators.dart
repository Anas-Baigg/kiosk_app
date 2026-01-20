class EmployeeValidators {
  static final RegExp _nameRegex = RegExp(r'^[a-zA-Z\s]+$');

  static final RegExp _passcodeRegex = RegExp(r'^\d{5}$');

  static String? validateName(String? raw) {
    final name = (raw ?? '').trim();
    if (name.isEmpty) return 'Name cannot be empty';
    if (!_nameRegex.hasMatch(name)) {
      return 'Name must contain only alphabets';
    }
    return null;
  }

  static String? validatePasscode(String? raw) {
    final pass = (raw ?? '').trim();
    if (pass.isEmpty) return 'Passcode cannot be empty';
    if (!_passcodeRegex.hasMatch(pass)) {
      return 'Passcode must be exactly 5 digits';
    }
    return null;
  }
}
