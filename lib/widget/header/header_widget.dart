import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/pages/login.dart';
import 'package:smart_task_app/provider/header_provider.dart';
import 'package:smart_task_app/provider/login_data.dart';
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
    return Consumer2<HeaderProvider, ThemeProvider>(
      builder: (context, headerProvider, themeProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfileOptions(context),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child:
                          userInfo.isNotEmpty &&
                                  userInfo[0]['profile_picture'] != null &&
                                  userInfo[0]['profile_picture'].isNotEmpty
                              ? Image.network(userInfo[0]['profile_picture'])
                              : Text(
                                getInitials(
                                  userInfo.isNotEmpty
                                      ? userInfo[0]['first_name']
                                      : '',
                                ),
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 253, 253),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userInfo.isNotEmpty ? userInfo[0]['first_name'] : '',
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
                  const Spacer(),
                  PopupMenuButton(
                    icon: const Icon(Icons.menu),
                    onSelected: (value) => _handleMenuOption(context, value),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Text('Profile Settings'),
                          ),
                          const PopupMenuItem(
                            value: 'theme',
                            child: Text('Toggle Theme'),
                          ),
                          const PopupMenuItem(
                            value: 'language',
                            child: Text('Language'),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Text('Logout'),
                          ),
                        ],
                  ),
                  IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                  IconButton(
                    icon: Icon(
                      headerProvider.showNotifications
                          ? Icons.notifications_outlined
                          : Icons.notifications_off_outlined,
                    ),
                    onPressed: () {
                      headerProvider.toggleNotifications();
                      _showNotificationToggleMessage(
                        context,
                        headerProvider.showNotifications,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SearchBar(
                hintText: 'Search...',
                leading: const Icon(Icons.search),
                onChanged: (value) {
                  // Handle search
                },
              ),
            ],
          ),
        );
      },
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
              ],
            ),
          ),
    );
  }

  void _handleMenuOption(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        _showProfileOptions(context);
        break;
      case 'theme':
        context.read<ThemeProvider>().toggleTheme();
        break;
      case 'language':
        _showLanguageOptions(context);
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLanguageOptions(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('English'),
                  onTap: () {
                    // Handle language change
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Spanish'),
                  onTap: () {
                    // Handle language change
                    Navigator.pop(context);
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

  void _showNotificationToggleMessage(BuildContext context, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'Notifications enabled' : 'Notifications disabled',
        ),
        duration: const Duration(seconds: 2),
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
