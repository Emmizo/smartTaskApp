import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final String date;
  final int members;
  final int tasks;
  final List<dynamic> team; // Add team data

  const ProjectCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.date,
    required this.members,
    required this.tasks,
    required this.team, // Mark team as required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CD9AC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.games, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CD9AC).withOpacity(0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Play your way and experience\nof gaming at home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(
                        6,
                        (index) => Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$tasks',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.link, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '09',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      height: 24, // Provide a bounded height for the Stack
                      width: 80, // Provide a bounded width for the Stack
                      child: Stack(
                        children: List.generate(
                          team.length, // Use team length instead of a fixed number
                          (index) => Positioned(
                            left: index * 20.0,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  167,
                                  149,
                                  149,
                                ), // Fallback color
                                backgroundImage: _getAvatarImage(
                                  index,
                                ), // Use image if available
                                child: _getAvatarFallback(
                                  index,
                                ), // Fallback icon if no image
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF4CD9AC),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Progress ${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  /// Returns the image for the avatar at the given index.
  ImageProvider? _getAvatarImage(int index) {
    if (index < team.length && team[index]['profile_picture'] != null) {
      return NetworkImage(team[index]['profile_picture']);
    }
    return null; // No image available
  }

  /// Returns the fallback widget (icon or text) for the avatar at the given index.
  Widget? _getAvatarFallback(int index) {
    if (_getAvatarImage(index) == null) {
      return const Icon(
        Icons.person, // Fallback icon
        size: 16,
        color: Colors.white,
      );
    }
    return null; // No fallback needed if an image is present
  }
}
