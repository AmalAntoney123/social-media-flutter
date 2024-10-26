import 'package:flutter/material.dart';
import 'package:incampus/student/notifications_page.dart';

class FeedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InCampus',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.chat, color: Colors.white),
            onPressed: () {
              // TODO: Implement chat page
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Feed', style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
