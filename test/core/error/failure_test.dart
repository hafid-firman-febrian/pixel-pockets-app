import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/error/failure.dart';

void main() {
  group('asFailure', () {
    test('returns the same Failure instance untouched', () {
      const failure = Failure(message: 'boom', type: FailureType.server);
      expect(asFailure(failure), same(failure));
    });

    test('wraps a non-Failure error with its string form', () {
      final result = asFailure(StateError('nope'));
      expect(result.message, contains('nope'));
      expect(result.type, FailureType.unknown);
    });

    test('wraps null with a generic message', () {
      final result = asFailure(null);
      expect(result.message, 'Something went wrong.');
      expect(result.type, FailureType.unknown);
    });
  });
}
