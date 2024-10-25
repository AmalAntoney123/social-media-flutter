import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AssignClassTeachersPage extends StatelessWidget {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Users'),
      ),
      body: StreamBuilder(
        stream: _database.child('users').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('No users found in the database'));
          }

          Map<dynamic, dynamic> users =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<MapEntry<dynamic, dynamic>> userList = users.entries.toList();

          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              MapEntry<dynamic, dynamic> entry = userList[index];
              Map<dynamic, dynamic> userData =
                  entry.value as Map<dynamic, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(userData['name'] ?? 'No name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${userData['email'] ?? 'No email'}'),
                      Text('Role: ${userData['role'] ?? 'No role'}'),
                      Text(
                          'Department: ${userData['department'] ?? 'Not specified'}'),
                      if (userData['teacherId'] != null)
                        Text('Teacher ID: ${userData['teacherId']}'),
                      Text('Status: ${userData['status'] ?? 'Not specified'}'),
                    ],
                  ),
                  trailing: userData['role'] == 'Teacher'
                      ? ElevatedButton(
                          child: Text(userData['isClassTeacher'] == true
                              ? 'Remove Class Teacher'
                              : 'Make Class Teacher'),
                          onPressed: () => _toggleClassTeacher(context,
                              entry.key, userData['isClassTeacher'] == true),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleClassTeacher(
      BuildContext context, String userId, bool isCurrentlyClassTeacher) async {
    try {
      await _database.child('users').child(userId).update({
        'isClassTeacher': !isCurrentlyClassTeacher,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isCurrentlyClassTeacher
                ? 'Teacher removed as class teacher successfully'
                : 'Teacher assigned as class teacher successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating class teacher status: $e')),
      );
    }
  }
}
