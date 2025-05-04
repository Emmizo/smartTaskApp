import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_task_app/widget/tasks/task_card.dart';
import 'package:smart_task_app/provider/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskCard displays title, project name, and due date', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: TaskCard(
            title: 'Test Task',
            projectName: 'Test Project',
            dueDate: '2025-05-01',
            progress: 0.5,
            team: [],
            status: 'Medium',
            tags: [],
          ),
        ),
      ),
    );

    expect(find.text('Test Task'), findsOneWidget);
    expect(find.textContaining('Project: Test Project'), findsOneWidget);
    expect(
      find.textContaining('Due: May'),
      findsOneWidget,
    ); // Partial match for formatted date
  });
}
