import 'package:flutter/material.dart';
import '../core/notification_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late Map<String, dynamic> _preferences;
  bool _loading = true;
  final List<String> _notificationTypes = [
    'task_assignment',
    'task_update',
    'project_update',
    'deadline_reminder',
    'mention',
    'comment',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _loading = true);
    _preferences = await NotificationService().getNotificationPreferences();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('General Preferences'),
                    _buildSwitchPreference(
                      'Enable Push Notifications',
                      _preferences['allowPush'] ?? true,
                      (value) => _updatePreference('allowPush', value),
                    ),
                    _buildSwitchPreference(
                      'Enable Email Notifications',
                      _preferences['allowEmail'] ?? false,
                      (value) => _updatePreference('allowEmail', value),
                    ),
                    _buildSwitchPreference(
                      'Enable Sounds',
                      _preferences['allowSound'] ?? true,
                      (value) => _updatePreference('allowSound', value),
                    ),
                    _buildSwitchPreference(
                      'Enable Vibration',
                      _preferences['allowVibration'] ?? true,
                      (value) => _updatePreference('allowVibration', value),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Mute Specific Notifications'),
                    ..._notificationTypes
                        .map((type) => _buildNotificationTypeToggle(type))
                        .toList(),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Mute Projects'),
                    // You can add project muting UI here
                    // This would typically be a list of projects with toggle switches
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSwitchPreference(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildNotificationTypeToggle(String type) {
    final isMuted =
        (_preferences['mutedTypes'] as List?)?.contains(type) ?? false;
    return ListTile(
      title: Text(_getTypeDisplayName(type)),
      trailing: Switch(
        value: !isMuted, // Switch shows "enabled" state
        onChanged: (enabled) async {
          if (enabled) {
            await NotificationService().unmuteNotificationType(type);
          } else {
            await NotificationService().muteNotificationType(type);
          }
          await _loadPreferences();
        },
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'task_assignment':
        return 'Task Assignments';
      case 'task_update':
        return 'Task Updates';
      case 'project_update':
        return 'Project Updates';
      case 'deadline_reminder':
        return 'Deadline Reminders';
      case 'mention':
        return 'Mentions';
      case 'comment':
        return 'Comments';
      default:
        return type;
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    await NotificationService().updateNotificationPreferences(
      {}, // Empty map since we're using named parameters
      allowPush: key == 'allowPush' ? value : null,
      allowEmail: key == 'allowEmail' ? value : null,
      allowSound: key == 'allowSound' ? value : null,
      allowVibration: key == 'allowVibration' ? value : null,
    );
    await _loadPreferences();
  }
}
