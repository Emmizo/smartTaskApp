import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_task_app/core/api_client.dart';
import 'package:smart_task_app/core/auth_utils.dart';
import 'package:smart_task_app/pages/list_all_project.dart';
import 'package:smart_task_app/provider/search_provider.dart';
import 'package:smart_task_app/widget/projects/project_card.dart';

class ProjectList extends StatefulWidget {
  const ProjectList({Key? key}) : super(key: key);

  @override
  _ProjectListState createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  Future<List<dynamic>>? futureProjects; // Nullable Future<List<dynamic>>
  final ApiClient _apiClient = ApiClient();
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProjects();
  }

  Future<void> _loadTokenAndFetchProjects() async {
    _token = await AuthUtils.getToken();
    if (_token != null) {
      // Perform the asynchronous work outside of setState
      final projectsFuture = _apiClient.projects(_token!);

      // Update the state synchronously
      setState(() {
        futureProjects = projectsFuture;
      });
    } else {
      // Handle the case where the token is null
      setState(() {
        futureProjects = Future.value([]); // Initialize with an empty list
      });

      print(futureProjects);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Projects',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListAllProject()),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF6B4EFF),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<dynamic>>(
          future: futureProjects,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No projects found.'));
            } else {
              final searchQuery =
                  Provider.of<SearchProvider>(context).query.toLowerCase();
              final filteredProjects =
                  snapshot.data!
                      .where((project) {
                        final projectName = project['name'].toLowerCase();
                        final projectDescription =
                            project['description'].toLowerCase();
                        final projectTags =
                            (project['tag'] as List<dynamic>)
                                .map((tag) => tag.toString().toLowerCase())
                                .toList();

                        return projectName.contains(searchQuery) ||
                            projectDescription.contains(searchQuery) ||
                            projectTags.any((tag) => tag.contains(searchQuery));
                      })
                      .take(4)
                      .toList();
              return filteredProjects.isEmpty
                  ? const Center(child: Text('No matching projects.'))
                  : SizedBox(
                    height: 400,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        return SizedBox(
                          width: 300,
                          child: ProjectCard(
                            title: project['name'],
                            subtitle: project['description'],
                            progress: (project['progress'] as num).toDouble(),
                            deadline: project['deadline'],
                            date: project['created_at'],
                            members: project['team'].length,
                            tasks: project['tasks'].length,
                            team:
                                project['team'].isNotEmpty
                                    ? project['team'][0]
                                    : [],
                            taskImages: project['tasks'],
                            tags:
                                project['tag'].isNotEmpty
                                    ? project['tag'][0]
                                    : [],
                          ),
                        );
                      },
                    ),
                  );
            }
          },
        ),
      ],
    );
  }
}
