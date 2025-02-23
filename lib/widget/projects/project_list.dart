import 'package:flutter/material.dart';
import 'package:smart_task_app/widget/projects/project_card.dart';

class ProjectList extends StatelessWidget {
  const ProjectList({Key? key}) : super(key: key);

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
        SizedBox(
          height: 400,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: const [
              SizedBox(
                width: 300, // Define a fixed width for each card
                child: ProjectCard(
                  title: 'Gaming Platform',
                  subtitle: 'Mobile App',
                  progress: 0.78,
                  date: 'June 18, 2022',
                  members: 3,
                  tasks: 16,
                ),
              ),
              SizedBox(
                width: 300, // Define a fixed width for each card
                child: ProjectCard(
                  title: 'Another Project',
                  subtitle: 'Web & Mobile App',
                  progress: 0.5,
                  date: 'June 19, 2022',
                  members: 2,
                  tasks: 10,
                ),
              ),
              // Add more ProjectCard widgets
            ],
          ),
        ),
      ],
    );
  }
}
