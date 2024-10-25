// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:incampus/student/feed_page.dart';
import 'package:incampus/student/for_you_page.dart';
import 'package:incampus/student/profile_page.dart';
import 'package:incampus/student/reels_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';

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
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _showNewContentDialog();
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
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
      case 3:
        return ReelsPage();
      case 4:
        return ProfilePage();
      default:
        return FeedPage();
    }
  }

  void _showNewContentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Content'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text('New Post'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewPost();
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text('New Reel'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewReel();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createNewPost() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);
      String fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}.jpg';

      try {
        // Upload image to Firebase Storage
        TaskSnapshot snapshot =
            await FirebaseStorage.instance.ref(fileName).putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Save post metadata to Firebase Realtime Database
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await FirebaseDatabase.instance.ref('posts/$userId').push().set({
            'imageUrl': downloadUrl,
            'timestamp': ServerValue.timestamp,
            'type': 'post',
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Post created successfully')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
      }
    }
  }

  Future<void> _createNewReel() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      File file = File(video.path);
      String fileName = 'reels/${DateTime.now().millisecondsSinceEpoch}.mp4';

      try {
        // Upload video to Firebase Storage
        TaskSnapshot snapshot =
            await FirebaseStorage.instance.ref(fileName).putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Save reel metadata to Firebase Realtime Database
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await FirebaseDatabase.instance.ref('reels/$userId').push().set({
            'videoUrl': downloadUrl,
            'timestamp': ServerValue.timestamp,
            'type': 'reel',
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Reel created successfully')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to create reel: $e')));
      }
    }
  }
}
