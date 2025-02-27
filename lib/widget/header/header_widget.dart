import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/core/user_service.dart';
import 'package:smart_task_app/pages/login.dart';
import 'package:smart_task_app/provider/header_provider.dart';
import 'package:smart_task_app/provider/login_data.dart';
import 'package:smart_task_app/provider/search_provider.dart';
import 'package:smart_task_app/provider/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    getUserResult();

    // Add a test notification after widget initialization for testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Uncomment the line below to test adding a notification when the app starts
      // NotificationService().testNotification();
    });
  }

  void getUserResult() async {
    final SharedPreferences prefs = await _prefs;
    String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      try {
        List<dynamic> userDataMap = jsonDecode(userData);

        String? token = userDataMap[0]['token'];

        if (token != null) {
          await context.read<LoginData>().setUserInfo(token);

          if (mounted) {
            setState(() {
              final loginData = Provider.of<LoginData>(context, listen: false);
              userInfo = loginData.getUserData; // Now types match

              widget.onDataPassed(userInfo);
            });
          }
        }
      } catch (e) {
        print("Error decoding JSON here: $e");
      }
    }
  }

  logOut() async {
    final SharedPreferences prefs = await _prefs;
    // await prefs.remove('token');
    await prefs.remove('userData');
    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userId = userInfo.isNotEmpty ? userInfo[0]['id'].toString() : '';
    return Consumer2<HeaderProvider, ThemeProvider>(
      builder: (context, headerProvider, themeProvider, _) {
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
                                userInfo.isNotEmpty &&
                                        userInfo[0]['profile_picture'] !=
                                            null &&
                                        userInfo[0]['profile_picture']
                                            .isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Hero(
                                        tag:
                                            "profile-${userInfo[0]['profile_picture']}", // Unique tag based on the image URL
                                        child: Image.network(
                                          userInfo[0]['profile_picture'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                    : Text(
                                      getInitials(
                                        userInfo.isNotEmpty
                                            ? userInfo[0]['first_name']
                                            : '',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                          if (userId.isNotEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: buildOnlineStatusIndicator(userId),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Hi ${userInfo.isNotEmpty ? userInfo[0]['fovorite_name'] : ''}, ${headerProvider.greeting}!',
                            style: const TextStyle(color: Colors.grey),
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
                            print(
                              "Notification icon clicked. Count: ${headerProvider.notifications.length}",
                            );
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
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              context.read<SearchProvider>().updateQuery(value);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search projects...',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
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

  Widget buildOnlineStatusIndicator(String userId) {
    return StreamBuilder<bool>(
      stream: UserService.getUserOnlineStatus(userId),
      builder: (context, snapshot) {
        // Add error handling and loading states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 12,
            height: 12,
          ); // Empty placeholder while loading
        }

        bool isOnline = snapshot.data ?? false;
        return Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    final headerProvider = Provider.of<HeaderProvider>(context, listen: false);

    print(
      "Showing notifications modal. Count: ${headerProvider.notifications.length}",
    );

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
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
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
                                  // Handle notification tap (navigate to related content)
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
    List<String> names = fullname.split(' ');
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
