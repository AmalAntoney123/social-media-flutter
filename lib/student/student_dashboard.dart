// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:incampus/student/feed_page.dart';
import 'package:incampus/student/for_you_page.dart';
import 'package:incampus/student/profile_page.dart';
import 'package:incampus/student/reels_page.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;

  // Define dark theme colors
  final Color _primaryColor = Colors.black;
  final Color _accentColor = Colors.blue[700]!;
  final Color _backgroundColor = Color(0xFF121212);
  final Color _surfaceColor = Color(0xFF1E1E1E);
  final Color _onSurfaceColor = Colors.white;

  void _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: _primaryColor,
        hintColor: _accentColor,
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: _surfaceColor,
          selectedItemColor: _accentColor,
          unselectedItemColor: Colors.grey,
        ),
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: _primaryColor,
          onPrimary: _onSurfaceColor,
          secondary: _accentColor,
          onSecondary: _onSurfaceColor,
          error: Colors.red,
          onError: _onSurfaceColor,
          background: _backgroundColor,
          onBackground: _onSurfaceColor,
          surface: _surfaceColor,
          onSurface: _onSurfaceColor,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('InCampus',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: _onSurfaceColor)),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications, color: _onSurfaceColor),
              onPressed: () {
                // TODO: Implement notifications page
              },
            ),
            IconButton(
              icon: Icon(Icons.chat, color: _onSurfaceColor),
              onPressed: () {
                // TODO: Implement chat page
              },
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.add_box), label: ''),
            BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return FeedPage();
      case 1:
        return ForYouPage();
      case 2:
        return _buildNewPost();
      case 3:
        return ReelsPage();
      case 4:
        return ProfilePage();
      default:
        return FeedPage();
    }
  }

  Widget _buildNewPost() {
    return Center(
        child: Text('New Post', style: TextStyle(color: _onSurfaceColor)));
    // TODO: Implement new post functionality
  }
}
