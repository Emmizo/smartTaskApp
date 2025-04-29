import 'package:flutter/material.dart';

import '../widget/header/header_widget.dart';
import '../widget/navigation/bottom_nav_bar.dart';
import '../widget/projects/project_list.dart';
import '../widget/projects/project_modal_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 180.0, // Height of the expanded header
              floating: false, // AppBar will not float
              pinned: false, // AppBar will not stay pinned at the top
              snap: false, // AppBar will not snap into view
              flexibleSpace: FlexibleSpaceBar(
                background: HeaderWidget(
                  scaffoldKey: _scaffoldKey,
                  selectedIndex: _selectedIndex,
                  onDataPassed: (data) {
                    setState(() {});
                  },
                ),
              ),
            ),
            // SliverList for the scrollable content
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return const ProjectList(); // Your ProjectList widget
                },
                childCount: 1, // Only one item (ProjectList)
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call the global project modal service
          ProjectModalService.showCreateProjectModal();
        },
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
