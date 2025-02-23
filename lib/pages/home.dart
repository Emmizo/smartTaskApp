import 'package:flutter/material.dart';
import 'package:smart_task_app/widget/header/header_widget.dart';
import 'package:smart_task_app/widget/navigation/bottom_nav_bar.dart';
import 'package:smart_task_app/widget/projects/project_list.dart';
import 'package:smart_task_app/widget/tasks/task_list.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: const [
            HeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [ProjectList(), TaskList()]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
