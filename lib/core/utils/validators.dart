/// Local Day 2 preview rules; not a backend authentication policy.
abstract final class Validators {
  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Enter your email address.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? previewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your password.';
    }
    if (value.length < 8) {
      return 'Use at least 8 characters for this preview.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Add at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Add at least one number.';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_+\-=\[\]\\/;~`]').hasMatch(value)) {
      return 'Add at least one special character.';
    }
    return null;
  }
}
