import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/helpers/error_helpers.dart';

void main() {
  group('friendlyError - network errors', () {
    test('SocketException returns wifi_off icon and "No internet"', () {
      final result = friendlyError(Exception('SocketException: Connection refused'));
      expect(result.icon, Icons.wifi_off);
      expect(result.message, contains('No internet'));
    });

    test('network error returns wifi_off icon', () {
      final result = friendlyError(Exception('NetworkError: failed'));
      expect(result.icon, Icons.wifi_off);
      expect(result.message, contains('No internet'));
    });

    test('failed host lookup returns wifi_off icon', () {
      final result = friendlyError(Exception('Failed host lookup: example.com'));
      expect(result.icon, Icons.wifi_off);
      expect(result.message, contains('No internet'));
    });

    test('clientexception returns wifi_off icon', () {
      final result = friendlyError(Exception('ClientException: Connection reset'));
      expect(result.icon, Icons.wifi_off);
      expect(result.message, contains('No internet'));
    });
  });

  group('friendlyError - rate limiting', () {
    test('resource-exhausted returns hourglass_top and "busy"', () {
      final result = friendlyError(Exception('resource-exhausted'));
      expect(result.icon, Icons.hourglass_top);
      expect(result.message, contains('math engine is busy'));
    });

    test('429 status code returns hourglass_top', () {
      final result = friendlyError(Exception('HTTP 429 Too Many Requests'));
      expect(result.icon, Icons.hourglass_top);
      expect(result.message, contains('busy'));
    });
  });

  group('friendlyError - timeout', () {
    test('deadline-exceeded returns timer_off and "taking too long"', () {
      final result = friendlyError(Exception('deadline-exceeded'));
      expect(result.icon, Icons.timer_off);
      expect(result.message, contains('taking too long'));
    });

    test('timeout returns timer_off', () {
      final result = friendlyError(Exception('timeout occurred'));
      expect(result.icon, Icons.timer_off);
      expect(result.message, contains('taking too long'));
    });
  });

  group('friendlyError - authentication', () {
    test('unauthenticated returns lock_outline and "session expired"', () {
      final result = friendlyError(Exception('unauthenticated'));
      expect(result.icon, Icons.lock_outline);
      expect(result.message, contains('session has expired'));
    });

    test('permission-denied returns lock_outline', () {
      final result = friendlyError(Exception('permission-denied'));
      expect(result.icon, Icons.lock_outline);
      expect(result.message, contains('session has expired'));
    });
  });

  group('friendlyError - precondition', () {
    test('failed-precondition returns error_outline and "wrong on our end"', () {
      final result = friendlyError(Exception('failed-precondition'));
      expect(result.icon, Icons.error_outline);
      expect(result.message, contains('wrong on our end'));
    });
  });

  group('friendlyError - unknown errors', () {
    test('unknown error returns error_outline and "Something went wrong"', () {
      final result = friendlyError(Exception('some random error'));
      expect(result.icon, Icons.error_outline);
      expect(result.message, contains('Something went wrong'));
    });

    test('empty error returns generic message', () {
      final result = friendlyError(Exception(''));
      expect(result.icon, Icons.error_outline);
      expect(result.message, contains('Something went wrong'));
    });

    test('non-Exception object returns generic message', () {
      final result = friendlyError('just a string error');
      expect(result.icon, Icons.error_outline);
      expect(result.message, contains('Something went wrong'));
    });
  });
}
