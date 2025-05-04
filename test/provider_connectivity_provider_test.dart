import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_app/provider/connectivity_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Commented out: These tests require connectivity_plus plugin and should be mocked or skipped in CI.
  // group('ConnectivityProvider', () {
  //   late ConnectivityProvider provider;

  //   setUp(() {
  //     provider = ConnectivityProvider();
  //   });

  //   test('should instantiate ConnectivityProvider', () {
  //     expect(provider, isA<ConnectivityProvider>());
  //   });

  //   test('initial isOnline is true or false', () {
  //     expect(provider.isOnline, isA<bool>());
  //   });
  // });
}
