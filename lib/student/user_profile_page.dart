import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incampus/student/post_detail_screen.dart';
import 'package:incampus/student/reel_detail_screen.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isFriend;
  final Function(String, bool) onFriendStatusChanged;

  UserProfilePage({
    required this.user,
    required this.isFriend,
    required this.onFriendStatusChanged,
  });

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late bool _isFriend;
  late bool _requestSent;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _reels = [];

  // Define dark theme colors
  final Color _primaryColor = Colors.black;
  final Color _accentColor = Colors.blue[700]!;
  final Color _backgroundColor = Color(0xFF121212);
  final Color _surfaceColor = Color(0xFF1E1E1E);
  final Color _onSurfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkFriendshipStatus();
    _loadUserContent();
  }

  void _checkFriendshipStatus() async {
    DataSnapshot friendSnapshot = await _database.child('users/$_currentUserId/friends/${widget.user['uid']}').get();
    DataSnapshot requestSnapshot = await _database.child('users/${widget.user['uid']}/friendRequests/$_currentUserId').get();
    
    setState(() {
      _isFriend = friendSnapshot.exists;
      _requestSent = requestSnapshot.exists;
    });
  }

  void _sendFriendRequest() async {
    await _database.child('users/${widget.user['uid']}/friendRequests/$_currentUserId').set(true);
    setState(() {
      _requestSent = true;
    });
  }

  void _toggleFriendship() async {
    if (_isFriend) {
      await _database
          .child('friendships')
          .child(_currentUserId)
          .child(widget.user['id'])
          .remove();
      await _database
          .child('friendships')
          .child(widget.user['id'])
          .child(_currentUserId)
          .remove();
    } else {
      await _database
          .child('friendships')
          .child(_currentUserId)
          .child(widget.user['id'])
          .set(true);
      await _database
          .child('friendships')
          .child(widget.user['id'])
          .child(_currentUserId)
          .set(true);
    }

    setState(() {
      _isFriend = !_isFriend;
    });
    widget.onFriendStatusChanged(widget.user['id'], _isFriend);
  }

  void _loadUserContent() async {
    if (widget.user['isPublic'] ?? false || _isFriend) {
      DatabaseEvent postsEvent =
          await _database.child('posts').child(widget.user['uid']).once();
      DatabaseEvent reelsEvent =
          await _database.child('reels').child(widget.user['uid']).once();

      if (postsEvent.snapshot.value != null) {
        Map<dynamic, dynamic> postsMap =
            postsEvent.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _posts = postsMap.entries
              .map((entry) => {
                    'id': entry.key,
                    ...Map<String, dynamic>.from(entry.value as Map)
                  })
              .toList();
        });
      }

      if (reelsEvent.snapshot.value != null) {
        Map<dynamic, dynamic> reelsMap =
            reelsEvent.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _reels = reelsMap.entries
              .map((entry) => {
                    'id': entry.key,
                    ...Map<String, dynamic>.from(entry.value as Map)
                  })
              .toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPublic = widget.user['isPublic'] ?? false;

    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: _primaryColor,
        hintColor: _accentColor,
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          elevation: 0,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: _accentColor,
          unselectedLabelColor: _onSurfaceColor,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.user['name'],
              style: TextStyle(color: _onSurfaceColor)),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              _buildProfileStats(),
              _buildBio(),
              _buildFriendshipButton(),
              if (isPublic || _isFriend) ...[
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.play_circle_outline)),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.5, // Adjust this value as needed
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsGrid(),
                      _buildReelsGrid(),
                    ],
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'This profile is private. Add as a friend to see posts and reels.',
                    style: TextStyle(color: _onSurfaceColor),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(widget.user['profilePicture'] ??
                'https://via.placeholder.com/150'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user['name'],
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _onSurfaceColor),
                ),
                Text(widget.user['department'] ?? 'No department',
                    style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return FutureBuilder<DataSnapshot>(
      future: _database.child('users/${widget.user['uid']}/friends').get(),
      builder: (context, snapshot) {
        int friendCount = snapshot.hasData ? snapshot.data!.children.length : 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatColumn(_posts.length.toString(), 'Posts'),
            _buildStatColumn(friendCount.toString(), 'Friends'),
          ],
        );
      },
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _onSurfaceColor)),
        Text(label, style: TextStyle(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildBio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        widget.user['bio'] ?? 'No bio available',
        style: TextStyle(color: _onSurfaceColor),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildFriendshipButton() {
    if (_isFriend) {
      return ElevatedButton(
        onPressed: null,
        child: Text('Friends'),
        style: ElevatedButton.styleFrom(
          foregroundColor: _onSurfaceColor,
          backgroundColor: Colors.grey[800],
          minimumSize: Size(double.infinity, 36),
        ),
      );
    } else if (_requestSent) {
      return ElevatedButton(
        onPressed: null,
        child: Text('Friend Request Sent'),
        style: ElevatedButton.styleFrom(
          foregroundColor: _onSurfaceColor,
          backgroundColor: Colors.grey[800],
          minimumSize: Size(double.infinity, 36),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: _sendFriendRequest,
        child: Text('Send Friend Request'),
        style: ElevatedButton.styleFrom(
          foregroundColor: _onSurfaceColor,
          backgroundColor: _accentColor,
          minimumSize: Size(double.infinity, 36),
        ),
      );
    }
  }

  Widget _buildPostsGrid() {
    if (_posts.isEmpty) {
      return Center(
          child: Text('No posts available',
              style: TextStyle(color: _onSurfaceColor)));
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(
                  postId: _posts[index]['id'],
                  post: _posts[index],
                  userId: widget.user['uid'],
                ),
              ),
            );
          },
          child: Image.network(
            _posts[index]['imageUrl'],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey,
                child: Icon(Icons.error, color: Colors.white),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid() {
    if (_reels.isEmpty) {
      return Center(
          child: Text('No reels available',
              style: TextStyle(color: _onSurfaceColor)));
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReelDetailScreen(
                  reelId: _reels[index]['id'],
                  videoUrl: _reels[index]['videoUrl'] ?? '',
                  uploaderId: widget.user['uid'],
                  description: _reels[index]['description'] ?? '',
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _reels[index]['thumbnailUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey,
                    child: Icon(Icons.error, color: Colors.white),
                  );
                },
              ),
              Center(
                child: Icon(Icons.play_circle_outline,
                    size: 40, color: _accentColor),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
