import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/auth_utils.dart';
import '../core/notification_service.dart';
import '../core/online_status_indicator.dart';
import '../provider/connectivity_provider.dart';
import '../provider/search_provider.dart';
import '../provider/theme_provider.dart';
import '../widget/header/header_widget.dart';
import '../widget/navigation/bottom_nav_bar.dart';
import '../widget/projects/project_modal_service.dart';

class ListAllProject extends StatefulWidget {
  const ListAllProject({super.key});

  @override
  State<ListAllProject> createState() => _ListAllProjectState();
}

class _ListAllProjectState extends State<ListAllProject> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<List<dynamic>>? futureProjects;
  final ApiClient _apiClient = ApiClient();
  String? _token;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allProjects = [];
  List<dynamic> _filteredProjects = [];
  final String _sortBy = 'name';
  final String _selectedMonth = 'All';
  int _selectedIndex = 1;
  Timer? _deadlineCheckTimer;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_onSearchChanged);

    Timer.periodic(const Duration(hours: 1), (Timer timer) {
      _checkDeadlinesAndNotify();
    });
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTokenAndFetchProjects();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _deadlineCheckTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _loadTokenAndFetchProjects() async {
    _token = await AuthUtils.getToken();
    if (_token != null) {
      final connectivityProvider = Provider.of<ConnectivityProvider>(
        // ignore: use_build_context_synchronously
        context,
        listen: false,
      );

      if (connectivityProvider.isOnline) {
        await _fetchProjectsFromApi();
      } else {
        await _loadProjectsFromPrefs();
      }
    } else {
      if (mounted) {
        setState(() {
          _allProjects = [];
          _filteredProjects = [];
        });
      }
    }
  }

  Future<void> _fetchProjectsFromApi() async {
    try {
      final projects = await _apiClient.projects(_token!);
      if (mounted) {
        setState(() {
          _allProjects = projects;
          _filteredProjects = projects;
          _applyFilters();
        });
      }
      _prefs.setString('allProjects', jsonEncode(projects));
    } catch (e) {
      await _loadProjectsFromPrefs();
    }
  }

  Future<void> _loadProjectsFromPrefs() async {
    final String? storedProjects = _prefs.getString('allProjects');
    if (storedProjects != null && storedProjects.isNotEmpty) {
      final projects = jsonDecode(storedProjects) as List<dynamic>;
      setState(() {
        _allProjects = projects;
        _filteredProjects = projects;
        _applyFilters();
      });
    } else {
      setState(() {
        _allProjects = [];
        _filteredProjects = [];
      });
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _checkDeadlinesAndNotify() {
    final now = DateTime.now();
    for (var project in _allProjects) {
      final deadline = DateTime.tryParse(project['deadline'] ?? '');

      if (deadline != null) {
        final difference = deadline.difference(now).inDays;
        if (difference == 1) {
          // Deadline is in one day
          final projectName = project['name'] ?? 'Unnamed Project';
          final teamMembers = project['team'] ?? [];
          final projectId = project['id'] ?? '';
          for (var member in teamMembers) {
            final memberName = '${member['first_name']} ${member['last_name']}';
            NotificationService().showProjectDeadlineNotification(
              '$memberName Deadline Approaching',
              projectName,
              /*  'The deadline for $projectName is in one day.', */
              deadline,
              projectId,
            );
          }
        }
      }
    }
  }

  void _applyFilters() {
    if (_selectedIndex == 1) {
      final query =
          Provider.of<SearchProvider>(
            context,
            listen: false,
          ).query.toLowerCase();
      setState(() {
        _filteredProjects =
            _allProjects.where((project) {
              final name = project['name']?.toString().toLowerCase() ?? '';
              final description =
                  project['description']?.toString().toLowerCase() ?? '';
              final deadline = project['deadline']?.toString() ?? '';

              // Apply search filter
              final matchesSearch =
                  name.contains(query) || description.contains(query);

              // Apply month filter
              final matchesMonth =
                  _selectedMonth == 'All' ||
                  _isProjectInMonth(deadline, _selectedMonth);

              return matchesSearch && matchesMonth;
            }).toList();

        _sortProjects(); // Sort projects after filtering
      });
    }
  }

  bool _isProjectInMonth(String deadline, String month) {
    if (deadline.isEmpty) return false;
    final date = DateTime.tryParse(deadline);
    if (date == null) return false;

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final projectMonth = monthNames[date.month - 1];
    return projectMonth == month;
  }

  void _sortProjects() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredProjects.sort(
            (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''),
          );
          break;
        case 'deadline':
          _filteredProjects.sort((a, b) {
            final deadlineA = a['deadline']?.toString() ?? '';
            final deadlineB = b['deadline']?.toString() ?? '';
            return deadlineA.compareTo(deadlineB);
          });
          break;
        case 'progress':
          _filteredProjects.sort((a, b) {
            final progressA = (a['progress'] as num).toDouble();
            final progressB = (b['progress'] as num).toDouble();
            return progressB.compareTo(
              progressA,
            ); // Sort by descending progress
          });
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ConnectivityProvider>(context);

    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: 180.0,
                  automaticallyImplyLeading: false,
                  floating: false,
                  pinned: false,
                  snap: false,
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
                SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    return _buildProjectCard(_filteredProjects[index]);
                  }, childCount: _filteredProjects.length),
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
              ProjectModalService.showCreateProjectModal();
            },
            backgroundColor: const Color(0xFF6B4EFF),
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final double progress = (project['progress'] as num).toDouble();
    const Color color = Color(0xFF4CD9AC);

    final List<dynamic> teamMembers = project['team'];
    final List<String> teamMemberNames =
        teamMembers
            .map((member) => '${member['first_name']} ${member['last_name']}')
            .toList();
    final List<String> teamMemberIds =
        teamMembers.map((member) => '${member['id']}').toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: themeProvider.getAdaptiveCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.getAdaptiveCardColor(context),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['name'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deadline: ${project['deadline'] ?? 'No Deadline'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 45,
                      width: 45,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project['description'] ?? 'No Description',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Team Members',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (int i = 0; i < teamMemberNames.length; i++)
                              if (i < 3)
                                Stack(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(
                                        right:
                                            i == teamMemberNames.length - 1
                                                ? 0
                                                : 8,
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: color.withOpacity(0.2),
                                        child: Text(
                                          teamMemberNames[i].substring(0, 1),
                                          style: const TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: OnlineStatusIndicator.build(
                                        teamMemberIds[i],
                                      ),
                                    ),
                                  ],
                                )
                              else if (i == 3)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[200],
                                    child: Text(
                                      '+${teamMemberNames.length - 3}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.visibility,
                        size: 16,
                        color: color,
                      ),
                      label: const Text(
                        'View Details',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        backgroundColor: color.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
