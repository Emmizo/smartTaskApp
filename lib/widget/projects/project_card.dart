import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final String date;
  final int members;
  final int tasks;
  final String deadline;
  final List<dynamic> team;
  final List<dynamic> taskImages;
  final List<dynamic> tags;

  const ProjectCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.date,
    required this.members,
    required this.tasks,
    required this.deadline,
    required this.team,
    required this.taskImages,
    required this.tags,
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
                        subtitle.length > 17
                            ? '${subtitle.substring(0, 14)}...'
                            : subtitle,
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
                        Text(
                          subtitle.length > 60
                              ? '${subtitle.substring(0, 63)}...'
                              : subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Make tags scrollable horizontally
                        SizedBox(
                          height: 40, // Fixed height for the tags container
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: tags.length,
                            itemBuilder: (context, index) {
                              final tag = tags[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Chip(
                                  label: Text(
                                    tag['tag_name'],
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.grey[200],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      physics: const BouncingScrollPhysics(),
                      crossAxisCount: 3,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(taskImages.length, (index) {
                        final hasValidImage =
                            taskImages[index]['image'] != null &&
                            taskImages[index]['image'].isNotEmpty &&
                            team.isNotEmpty &&
                            team[0]['url'] != null &&
                            team[0]['url'].isNotEmpty;

                        if (hasValidImage) {
                          final imageUrl =
                              "${team[0]['url']}/${taskImages[index]['image']}";
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Silently handle image loading errors
                                  print("Failed to load image: $imageUrl");
                                },
                              ),
                            ),
                          );
                        } else {
                          // Return an empty container with just background color when no valid image
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          );
                        }
                      }),
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
                      height: 24,
                      width: 80,
                      child: Stack(
                        children: List.generate(
                          team.length,
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
                                backgroundColor: Colors.grey[400],
                                backgroundImage: _getAvatarImage(index),
                                child: _getAvatarFallback(index),
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

  ImageProvider? _getAvatarImage(int index) {
    if (index < team.length &&
        team[index]['profile_picture'] != null &&
        team[index]['profile_picture'].toString().isNotEmpty) {
      final profilePicture = team[index]['profile_picture'].toString();

      // Validate that the profile picture URL is not empty or malformed
      if (profilePicture.startsWith('http://') ||
          profilePicture.startsWith('https://')) {
        return NetworkImage(profilePicture);
      }
    }
    // Return null if there's no valid profile picture
    return null;
  }

  Widget _getAvatarFallback(int index) {
    // This now always returns a Widget (not Widget?)
    if (_getAvatarImage(index) == null) {
      return const Icon(Icons.person, size: 16, color: Colors.white);
    }
    return const SizedBox.shrink(); // Return an empty widget if there's an image
  }
}

// And then where you use these methods in your CircleAvatar:
