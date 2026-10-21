/// Shared form validation; account authorization remains backend-controlled.
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
}
