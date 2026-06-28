import 'package:flutter_test/flutter_test.dart';
import 'package:three_as_complex/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('mobile', () {
      test('valid 10-digit number starting with 9', () {
        expect(Validators.mobile('9876543210'), isNull);
      });
      test('valid number starting with 6', () {
        expect(Validators.mobile('6543210987'), isNull);
      });
      test('rejects 5-digit number', () {
        expect(Validators.mobile('98765'), isNotNull);
      });
      test('rejects number starting with 1', () {
        expect(Validators.mobile('1234567890'), isNotNull);
      });
      test('rejects empty string', () {
        expect(Validators.mobile(''), isNotNull);
      });
    });

    group('password', () {
      test('valid password', () {
        expect(Validators.password('demo1234'), isNull);
      });
      test('rejects short password', () {
        expect(Validators.password('abc'), isNotNull);
      });
      test('rejects empty password', () {
        expect(Validators.password(''), isNotNull);
      });
    });

    group('confirmPassword', () {
      test('matching passwords', () {
        expect(Validators.confirmPassword('demo1234', 'demo1234'), isNull);
      });
      test('mismatched passwords', () {
        expect(Validators.confirmPassword('demo1234', 'different'), isNotNull);
      });
    });

    group('otp', () {
      test('valid 4-digit OTP', () {
        expect(Validators.otp('1234'), isNull);
      });
      test('rejects letters', () {
        expect(Validators.otp('abcd'), isNotNull);
      });
      test('rejects empty', () {
        expect(Validators.otp(''), isNotNull);
      });
    });
  });
}
