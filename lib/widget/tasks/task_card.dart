import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/online_status_indicator.dart';
import '../../provider/theme_provider.dart';

class TaskCard extends StatelessWidget {
  final Map<dynamic, dynamic>? task;
  final String title;
  final String projectName;
  final String dueDate;
  final double progress;
  final String status;
  final List<dynamic> team;
  final List<dynamic> tags;
  final String searchQuery;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isOffline;

  const TaskCard({
    super.key,
    this.task,
    required this.title,
    required this.projectName,
    required this.dueDate,
    required this.progress,
    required this.team,
    required this.status,
    required this.tags,
    this.onEdit,
    this.onDelete,
    this.searchQuery = '',
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    // Format due date
    final DateTime parsedDate = DateTime.parse(dueDate);
    final String formattedDate = DateFormat('MMM d, yyyy').format(parsedDate);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Status color based on priority
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'high':
        statusColor = Colors.red;
        break;
      case 'medium':
        statusColor = Colors.orange;
        break;
      case 'low':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.getAdaptiveCardColor(context),
        borderRadius: BorderRadius.circular(12),
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
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF6B4EFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child:
                              searchQuery.isNotEmpty
                                  ? _highlightText(title, searchQuery)
                                  : Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                        Row(
                          children: [
                            if (isOffline)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cloud_off,
                                      size: 12,
                                      color: Colors.amber[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Offline',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.amber[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  searchQuery.isNotEmpty
                                      ? _highlightText(
                                        status,
                                        searchQuery,
                                        baseStyle: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      )
                                      : Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    searchQuery.isNotEmpty
                        ? _highlightText(
                          'Project: $projectName • Due: $formattedDate',
                          searchQuery,
                          baseStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                        : Text(
                          'Project: $projectName • Due: $formattedDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Team avatars (showing up to 3)
                        buildTeamAvatars(),

                        const SizedBox(width: 8),

                        // Tags
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: buildTags()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6B4EFF),
                          ),
                        ),
                        // Centered Text
                        Center(
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, color: Color(0xFF6B4EFF)),
                        iconSize: 20,
                        tooltip: 'Edit Task',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete,
                          color: Color.fromARGB(255, 240, 56, 1),
                        ),
                        iconSize: 20,
                        tooltip: 'Delete Task',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _highlightText(String text, String query, {TextStyle? baseStyle}) {
    if (query.isEmpty) {
      return Text(
        text,
        style:
            baseStyle ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final TextStyle defaultStyle =
        baseStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    final TextStyle highlightStyle = defaultStyle.copyWith(
      backgroundColor: Colors.yellow.withOpacity(0.3),
      fontWeight: FontWeight.w700,
    );

    final List<TextSpan> spans = [];
    final String lowercaseText = text.toLowerCase();
    final String lowercaseQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final int index = lowercaseText.indexOf(lowercaseQuery, start);
      if (index == -1) {
        // No more matches
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: defaultStyle));
        }
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: defaultStyle),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget buildTeamAvatars() {
    // Use a Stack to create the overlapping effect instead of negative margins
    return SizedBox(
      width: 30, // Adjust based on your needs
      height: 28, // Height of the avatars
      child: Stack(
        children: [
          // Add up to 3 team member avatars
          for (var i = 0; i < team.length && i < 3; i++) ...[
            Positioned(
              left: i * 16.0, // Overlap the avatars
              child: _buildAvatar(i),
            ),
          ],
          // Add the "+X" avatar if there are more than 3 team members
          if (team.length > 3)
            Positioned(left: 3 * 16.0, child: _buildMoreAvatar()),
        ],
      ),
    );
  }

  Widget _buildAvatar(int index) {
    final member = team[index];
    getTeam(int index) {
      final teamId = member['id'].toString();
      return OnlineStatusIndicator.build(teamId);
    }

    // Safely extract member properties with null checks
    final String name =
        member is Map
            ? (member['name']?.toString() ?? 'Unknown')
            : member.toString();

    final String? profilePicture =
        member is Map ? member['profile_picture']?.toString() : null;

    return Tooltip(
      message: '',
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  profilePicture != null && profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
              child:
                  profilePicture == null || profilePicture.isEmpty
                      ? const Icon(Icons.person, size: 16, color: Colors.grey)
                      : null,
            ),
          ),
          Positioned(right: 0, bottom: 0, child: getTeam(index)),
        ],
      ),
    );
  }

  Widget _buildMoreAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey[200],
        child: Text(
          '+${team.length - 3}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<Widget> buildTags() {
    final List<Widget> tagWidgets = [];

    for (final tagObj in tags) {
      // Extract the tag name from the tag object
      final String tagName = tagObj['tag_name'] as String;

      tagWidgets.add(
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              searchQuery.isNotEmpty
                  ? _highlightText(
                    tagName,
                    searchQuery,
                    baseStyle: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  )
                  : Text(
                    tagName,
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
        ),
      );
    }

    return tagWidgets;
  }
}
