import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_app/core/api_client.dart';

void main() {
  group('ApiClient', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    test('should instantiate ApiClient', () {
      expect(apiClient, isA<ApiClient>());
    });

    // This test is commented out to avoid timeout due to real network call.
    // In real tests, use a mock Dio or mock server.
    // test('should throw on invalid endpoint', () async {
    //   try {
    //     await apiClient.taskTags();
    //     expect(true, isTrue);
    //   } catch (e) {
    //     expect(e, isNotNull);
    //   }
    // });
  });
}
