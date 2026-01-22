import 'package:flutter_test/flutter_test.dart';

/// Tests for phone number validation
/// This validates the phone number format used in the app
void main() {
  group('Phone Number Validation Tests', () {
    test('Valid Ugandan phone numbers should pass', () {
      final validNumbers = [
        '0700123456',
        '0701234567',
        '0702345678',
        '0750123456',
        '0780123456',
        '0790123456',
      ];

      for (var number in validNumbers) {
        expect(isValidPhoneNumber(number), true,
            reason: '$number should be valid');
      }
    });

    test('Invalid phone numbers should fail', () {
      final invalidNumbers = [
        '',
        'abc',
        '123',
        '07001234', // Too short
        '070012345678', // Too long
        '0900123456', // Invalid prefix
        '+256700123456', // With country code (depends on requirements)
        '256700123456', // Without + sign
        '070 012 3456', // With spaces
        '0700-123-456', // With dashes
      ];

      for (var number in invalidNumbers) {
        expect(isValidPhoneNumber(number), false,
            reason: '$number should be invalid');
      }
    });

    test('Phone number normalization', () {
      // Normalization removes spaces, dashes, and trims
      expect(normalizePhoneNumber('0700123456'), '0700123456');
      expect(normalizePhoneNumber(' 0700123456 '), '0700123456');
      expect(normalizePhoneNumber('0700 123 456'), '0700123456');
      expect(normalizePhoneNumber('0700-123-456'), '0700123456');

      // After normalization, these should be valid
      expect(isValidPhoneNumber(normalizePhoneNumber('0700 123 456')), true);
      expect(isValidPhoneNumber(normalizePhoneNumber('0700-123-456')), true);
    });

    test('Phone number edge cases', () {
      expect(isValidPhoneNumber('0700000000'), true); // All zeros after prefix
      expect(isValidPhoneNumber('0799999999'), true); // All nines
      expect(isValidPhoneNumber('0000000000'), false); // Invalid prefix
    });

    test('Phone numbers with leading/trailing spaces should fail', () {
      expect(isValidPhoneNumber(' 0700123456 '), false);
    });

    test('Phone numbers with special characters should fail', () {
      expect(isValidPhoneNumber('0700-123-456'), false);
      expect(isValidPhoneNumber('(0700)123456'), false);
      expect(isValidPhoneNumber('0700.123.456'), false);
    });

    test('International format numbers should fail (unless allowed)', () {
      expect(isValidPhoneNumber('+256700123456'), false);
      expect(isValidPhoneNumber('00256700123456'), false);
    });

    test('Very large and very small numbers should fail', () {
      expect(isValidPhoneNumber('070012345678901234'), false);
      expect(isValidPhoneNumber('07'), false);
    });
  });
}

/// Validates Ugandan phone number format
/// Expected format: 07XX XXX XXX (10 digits starting with 07)
/// Does NOT accept spaces or dashes - must be exact format
bool isValidPhoneNumber(String phone) {
  if (phone.isEmpty) return false;

  // Check format: exactly 10 digits starting with 07, no spaces or special chars
  final regex = RegExp(r'^07[0-9]{8}$');
  return regex.hasMatch(phone);
}

/// Normalizes phone number by removing spaces and dashes
String normalizePhoneNumber(String phone) {
  return phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
}
