import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_task_app/widget/tasks/task_form_modal.dart';
import 'package:smart_task_app/provider/theme_provider.dart';
import 'package:smart_task_app/core/api_client.dart';

class MockApiClient extends ApiClient {
  @override
  Future<List<dynamic>> allUsers() async => [
    {'id': 1, 'name': 'Test User'},
  ];
  @override
  Future<List<dynamic>> taskTags() async => [
    {'id': 1, 'name': 'Test Tag'},
  ];
  @override
  Future<List<dynamic>> allTags() async => [];
  @override
  Future<List<dynamic>> projects(String token) async => [];
  @override
  Future<List<dynamic>> getAllProjects(String token) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskFormModal displays form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: TaskFormModal(
              apiClient: MockApiClient(),
              onTaskSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsWidgets);
    expect(find.widgetWithText(TextFormField, 'Task Title'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Due Date'), findsOneWidget);
  });
}
