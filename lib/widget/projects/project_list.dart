import 'package:flutter/material.dart';
import 'package:smart_task_app/core/api_client.dart';
import 'package:smart_task_app/core/auth_utils.dart';
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
      print("Token is null. User is not logged in.");
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
            children: const [
              Text(
                'Recent Projects',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text('View All', style: TextStyle(color: Color(0xFF6B4EFF))),
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
              return SizedBox(
                height: 400,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final project = snapshot.data![index];
                    return SizedBox(
                      width: 300,
                      child: ProjectCard(
                        title: project['name'],
                        subtitle: project['description'],
                        progress: 0.78, // Calculate dynamically
                        date: project['created_at'],
                        members: project['team'].length,
                        tasks: project['tasks'].length,
                        team: project['team'][0],
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
