import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(
              scaffoldKey: _scaffoldKey,
              selectedIndex: _selectedIndex,
              onDataPassed: (data) {
                setState(() {});
              },
            ),
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
