import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../core/notification_preferences_screen.dart';
import '../../core/notification_service.dart';
import '../../core/online_status_indicator.dart';
import '../../core/totp_service.dart';
import '../../core/user_service.dart';
import '../../pages/login.dart';
import '../../pages/two_fa_setup_screen.dart';
import '../../provider/all_task_provider.dart';
import '../../provider/connectivity_provider.dart';
import '../../provider/header_provider.dart';
import '../../provider/login_data.dart';
import '../../provider/online_status_provider.dart';
import '../../provider/search_provider.dart';

import '../../provider/theme_provider.dart';

class HeaderWidget extends StatefulWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Function(List<Map<String, dynamic>>) onDataPassed;
  final int selectedIndex;
  const HeaderWidget({
    super.key,
    required this.scaffoldKey,
    required this.selectedIndex,
    required this.onDataPassed,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  List<Map<String, dynamic>> userInfo = [];
  bool is2FAEnabled = false;
  @override
  void initState() {
    super.initState();
    getUserResult();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userInfo.isNotEmpty && userInfo[0]['id'] != null) {
        final String userId = userInfo[0]['id'].toString();
        UserService.ensureUserDocument(userId, online: true);
      }
    });
  }

  void getUserResult() async {
    final SharedPreferences prefs = await _prefs;
    final String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        final List<dynamic> userDataMap = jsonDecode(userData);

        final String? token = userDataMap[0]['token'];

        if (token != null) {
          // Check internet connectivity
          final connectivityProvider = Provider.of<ConnectivityProvider>(
            context,
            listen: false,
          );
          if (connectivityProvider.isOnline) {
            // ignore: use_build_context_synchronously
            await context.read<LoginData>().setUserInfo(token);

            if (mounted) {
              setState(() {
                final loginData = Provider.of<LoginData>(
                  context,
                  listen: false,
                );
                userInfo = loginData.getUserData;

                widget.onDataPassed(userInfo);

                // Set user ID in OnlineStatusProvider after getting user data
                if (userInfo.isNotEmpty && userInfo[0]['id'] != null) {
                  final String userId = userInfo[0]['id'].toString();
                  Provider.of<OnlineStatusProvider>(
                    context,
                    listen: false,
                  ).setUserId(userId);
                  UserService.ensureUserDocument(userId, online: true);
                }
              });
            }
          } else {
            // If no internet, use data from SharedPreferences
            if (mounted) {
              setState(() {
                userInfo = userDataMap.cast<Map<String, dynamic>>();
                widget.onDataPassed(userInfo);
              });
            }
          }
        }
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  logOut() async {
    if (!mounted) return;

    final SharedPreferences prefs = await _prefs;
    final taskProvider = Provider.of<AllTaskProvider>(context, listen: false);

    // Set offline status before logging out
    if (userInfo.isNotEmpty && userInfo[0]['id'] != null) {
      final String userId = userInfo[0]['id'].toString();
      await UserService.ensureUserDocument(userId, online: false);
      await Provider.of<OnlineStatusProvider>(context, listen: false).cleanup();
    }

    taskProvider.clearTasks();
    await prefs.remove('allProjects');
    await FirebaseAuth.instance.signOut();
    await prefs.remove('userData');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userId =
        userInfo.isNotEmpty ? userInfo[0]['id'].toString() : '';

    return Consumer2<HeaderProvider, ThemeProvider>(
      builder: (context, headerProvider, themeProvider, _) {
        final user = userInfo.isNotEmpty ? userInfo[0] : null;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Row (Fixed height)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Profile Avatar with GestureDetector
                    GestureDetector(
                      onTap: () => _showProfileOptions(context),
                      child: Stack(
                        clipBehavior:
                            Clip.none, // Ensures the status indicator is not clipped
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue,
                            child:
                                user != null &&
                                        user['profile_picture'] != null &&
                                        user['profile_picture'].isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Hero(
                                        tag:
                                            "profile-${user['profile_picture']}",
                                        child: Image.network(
                                          user['profile_picture'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                    : Text(
                                      getInitials(user?['first_name'] ?? ''),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                          if (userId.isNotEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: OnlineStatusIndicator.build(userId),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // User Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userInfo.isNotEmpty
                                ? userInfo[0]['first_name']
                                : '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Hi ${userInfo.isNotEmpty ? userInfo[0]['fovorite_name'] : ''}, ${headerProvider.greeting}!',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Theme Toggle Button
                    IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                    const SizedBox(width: 8), // Reduced space
                    // Notification Icon with Badge
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            _showNotifications(context);
                          },
                        ),
                        if (headerProvider.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                headerProvider.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Add Expanded to prevent layout overflow
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: themeProvider.getAdaptiveCardColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              context.read<SearchProvider>().updateQuery(value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search projects...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 224, 219, 219),
                                  width: 0.5,
                                ),
                              ),

                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),

                        // More widgets can be added here
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    final headerProvider = Provider.of<HeaderProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const NotificationPreferencesScreen(),
                              ),
                            );
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            headerProvider.markAllAsRead();
                            setState(() {});
                          },
                          child: const Text('Mark all as read'),
                        ),
                        TextButton(
                          onPressed: () {
                            headerProvider.clearNotifications();
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text('Clear all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    headerProvider.notifications.isEmpty
                        ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No notifications'),
                        )
                        : Expanded(
                          child: ListView.builder(
                            itemCount: headerProvider.notifications.length,
                            itemBuilder: (context, index) {
                              final notification =
                                  headerProvider.notifications[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      notification['read'] == true
                                          ? Colors.grey
                                          : Colors.blue,
                                  child: const Icon(
                                    Icons.notifications,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  notification['title'] ?? 'Notification',
                                ),
                                subtitle: Text(notification['body'] ?? ''),
                                trailing: Text(
                                  notification['time'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                onTap: () {
                                  headerProvider.markAsRead(index);
                                  setState(() {});
                                },
                              );
                            },
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Options',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    // Handle edit profile
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Change Profile Picture'),
                  onTap: () {
                    // Handle profile picture change
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Theme Settings'),
                  onTap: () {
                    context.read<ThemeProvider>().toggleTheme();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Two-Factor Authentication'),
                  trailing: Switch(
                    value: userInfo[0]['has_2fa_enabled'] == '1' ? true : false,
                    onChanged: (value) async {
                      if (!mounted) return;

                      // Close the drawer or bottom sheet or menu immediately (before any await)
                      Navigator.pop(context);

                      final prefs = await SharedPreferences.getInstance();
                      final String? userData = prefs.getString('userData');

                      if (!mounted) return;

                      if (userData == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User data not found')),
                        );
                        return;
                      }

                      final dynamic decodedData = jsonDecode(userData);
                      String token;

                      if (decodedData is List) {
                        token = decodedData[0]['token']?.toString() ?? '';
                      } else if (decodedData is Map) {
                        token = decodedData['token']?.toString() ?? '';
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid user data format'),
                          ),
                        );
                        return;
                      }

                      if (value) {
                        // Enable 2FA
                        final bool? setupComplete = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TwoFASetupScreen(),
                          ),
                        );

                        if (setupComplete == true && mounted) {
                          getUserResult(); // Refresh user data
                        }
                      } else {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Disable 2FA?'),
                                content: const Text(
                                  'This will reduce your account security.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text('Disable'),
                                  ),
                                ],
                              ),
                        );

                        if (confirmed == true) {
                          print(confirmed);
                          final response = await ApiClient().disable2FA(token);
                          if (response['success'] == true && mounted) {
                            await TOTPService.removeSecret();
                            await TOTPService.set2FAStatus(false);
                            getUserResult();
                          } else {
                            setState(() {
                              is2FAEnabled = true; // Reset if disabling failed
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  response['error'] ?? 'Failed to disable 2FA',
                                ),
                              ),
                            );
                          }
                        } else {
                          setState(() {
                            is2FAEnabled = true; // Reset if user cancels dialog
                          });
                        }
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  logOut();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}

String getInitials(String fullname) {
  if (fullname.isEmpty) {
    return ''; // Return empty string if name is empty
  } else {
    final List<String> names = fullname.split(' ');
    if (names.length == 1) {
      return names[0]
          .substring(0, 1)
          .toUpperCase(); // Return first character if only one word
    } else {
      String initials = '';
      for (var name in names) {
        if (name.isNotEmpty) {
          initials += name.substring(0, 1).toUpperCase();
        }
      }
      return initials;
    }
  }
}
