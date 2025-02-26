import 'package:flutter/material.dart';
import 'package:smart_task_app/core/api_client.dart';
import 'package:smart_task_app/core/auth_utils.dart';
import 'package:smart_task_app/widget/projects/project_modal_service.dart';

class ListAllProject extends StatefulWidget {
  const ListAllProject({super.key});

  @override
  State<ListAllProject> createState() => _ListAllProjectState();
}

class _ListAllProjectState extends State<ListAllProject> {
  Future<List<dynamic>>? futureProjects;
  final ApiClient _apiClient = ApiClient();
  String? _token;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allProjects = [];
  List<dynamic> _filteredProjects = [];
  String _sortBy = 'name';
  String _selectedMonth = 'All';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProjects();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTokenAndFetchProjects() async {
    _token = await AuthUtils.getToken();
    if (_token != null) {
      final projectsFuture = _apiClient.projects(_token!);

      projectsFuture
          .then((projects) {
            setState(() {
              _allProjects = projects;
              _filteredProjects = projects;
              _applyFilters(); // Apply filters after loading projects
            });
          })
          .catchError((error) {});

      setState(() {
        futureProjects = projectsFuture;
      });
    } else {
      setState(() {
        futureProjects = Future.value([]);
      });
    }
  }

  void _onSearchChanged() {
    _applyFilters(); // Apply filters when search text changes
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
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

  void _showSortByDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sort By'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Name'),
                onTap: () {
                  setState(() {
                    _sortBy = 'name';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Deadline'),
                onTap: () {
                  setState(() {
                    _sortBy = 'deadline';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Progress'),
                onTap: () {
                  setState(() {
                    _sortBy = 'progress';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMonthFilterDialog() {
    final monthNames = [
      'All',
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter By Month'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  monthNames.map((month) {
                    return ListTile(
                      title: Text(month),
                      onTap: () {
                        setState(() {
                          _selectedMonth = month;
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [_buildHeader(), Expanded(child: _buildProjectList())],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call the global project modal service
          ProjectModalService.showCreateProjectModal();
        },
        tooltip: 'Add New Project',
        child: const Icon(Icons.add),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Projects',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Projects',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showMonthFilterDialog,
                      child: Text(
                        _selectedMonth,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(color: Colors.grey[50]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Projects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showSortByDialog,
                  icon: const Icon(Icons.sort, size: 16),
                  label: const Text('Sort By'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: futureProjects,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No projects found.'));
                } else {
                  return ListView.builder(
                    itemCount: _filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = _filteredProjects[index];
                      return _buildProjectCard(project);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final double progress = (project['progress'] as num).toDouble();
    final Color color = _parseColor(project['color'] as String?);

    // Extract team members
    final List<dynamic> teamMembers = project['team'][0];
    final List<String> teamMemberNames =
        teamMembers
            .map((member) => '${member['first_name']} ${member['last_name']}')
            .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
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
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deadline: ${project['deadline'] ?? 'No Deadline'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
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
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (int i = 0; i < teamMemberNames.length; i++)
                              if (i < 3)
                                Container(
                                  margin: EdgeInsets.only(
                                    right:
                                        i == teamMemberNames.length - 1 ? 0 : 8,
                                  ),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: color.withOpacity(0.2),
                                    child: Text(
                                      teamMemberNames[i].substring(0, 1),
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
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
                      icon: Icon(Icons.visibility, size: 16, color: color),
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

  Color _parseColor(String? color) {
    switch (color) {
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue; // Default color
    }
  }
}
