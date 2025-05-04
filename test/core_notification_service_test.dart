import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_app/core/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    // Commented out: These tests require Firebase initialization and should be mocked or skipped in CI.
    // test('should instantiate NotificationService', () {
    //   expect(notificationService, isA<NotificationService>());
    // });

    // test('testNotification does not throw', () {
    //   expect(() => notificationService.testNotification(), returnsNormally);
    // });
  });
}
