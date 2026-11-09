import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Form Validation Tests', () {
    test('Valid email passes check', () {
      final email = 'student@example.com';
      final isValid = email.isNotEmpty && email.contains('@') && email.contains('.');
      expect(isValid, isTrue);
    });

    test('Invalid email fails check', () {
      final email = 'invalidemail';
      final isValid = email.isNotEmpty && email.contains('@') && email.contains('.');
      expect(isValid, isFalse);
    });

    test('Password shorter than 6 characters fails', () {
      final password = '12345';
      final isValid = password.length >= 6;
      expect(isValid, isFalse);
    });

    test('Password with 6 or more characters passes', () {
      final password = 'secure123';
      final isValid = password.length >= 6;
      expect(isValid, isTrue);
    });
  });
}
