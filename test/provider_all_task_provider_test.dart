import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_app/provider/all_task_provider.dart';

void main() {
  group('AllTaskProvider', () {
    late AllTaskProvider provider;

    setUp(() {
      provider = AllTaskProvider();
    });

    test('should instantiate AllTaskProvider', () {
      expect(provider, isA<AllTaskProvider>());
    });

    test('initial tasks list is empty', () {
      expect(provider.tasks, isEmpty);
    });
  });
}
