import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_app/core/offline_task_manager.dart';

void main() {
  group('OfflineTaskManager', () {
    late OfflineTaskManager manager;

    setUp(() {
      manager = OfflineTaskManager();
    });

    test('should instantiate OfflineTaskManager', () {
      expect(manager, isA<OfflineTaskManager>());
    });

    test('should have getOfflineTasks method', () {
      expect(manager.getOfflineTasks, isA<Function>());
    });
  });
}
