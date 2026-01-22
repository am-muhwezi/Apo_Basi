import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Test Suite', () {
    test('Simple arithmetic test', () {
      expect(2 + 2, equals(4));
      expect(10 - 5, equals(5));
      expect(3 * 3, equals(9));
    });

    test('String operations test', () {
      final driver = 'John Doe';
      expect(driver, contains('John'));
      expect(driver.split(' ').length, equals(2));
    });

    test('List operations test', () {
      final phoneNumbers = ['0700123456', '0700234567', '0700345678'];
      expect(phoneNumbers.length, equals(3));
      expect(phoneNumbers.first, equals('0700123456'));
      expect(phoneNumbers, contains('0700234567'));
    });
  });
}
