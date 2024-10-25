import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'overview_page.dart';
import 'teacher_approvals_page.dart';
import 'assign_class_teachers_page.dart';
import 'departments_management_page.dart';

class AdminDashboard extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      // Navigate to the login screen or home screen after logout
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Logout',
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Teacher Approvals'),
              Tab(text: 'User Manager'),
              Tab(text: 'Departments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewPage(),
            TeacherApprovalsPage(),
            AssignClassTeachersPage(),
            DepartmentsManagementPage(),
          ],
        ),
      ),
    );
  }
}
