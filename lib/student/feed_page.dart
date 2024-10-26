import 'package:flutter/material.dart';
import 'package:incampus/student/notifications_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:incampus/student/post_detail_screen.dart';
import 'package:incampus/student/user_profile_page.dart';
import 'package:incampus/student/profile_page.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _posts = [];
  bool _hasPendingRequests = false;

  @override
  void initState() {
    super.initState();
    _loadFriendsPosts();
    _checkPendingRequests();
  }

  Future<void> _loadFriendsPosts() async {
    setState(() {
      _posts.clear();
    });

    // First, fetch the current user's friends
    DatabaseEvent friendsEvent =
        await _database.child('users/$_currentUserId/friends').once();
    Set<String> friendIds = {};
    if (friendsEvent.snapshot.value != null) {
      Map<dynamic, dynamic> friends =
          friendsEvent.snapshot.value as Map<dynamic, dynamic>;
      friendIds = friends.keys.cast<String>().toSet();
    }

    // Add the current user's ID to show their own posts
    friendIds.add(_currentUserId);

    DatabaseEvent postsEvent = await _database.child('posts').once();
    if (postsEvent.snapshot.value != null) {
      Map<dynamic, dynamic> allPosts =
          postsEvent.snapshot.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> newPosts = [];

      allPosts.forEach((userId, userPosts) {
        // Only process posts from friends and the current user
        if (friendIds.contains(userId) && userPosts is Map<dynamic, dynamic>) {
          userPosts.forEach((postId, postData) {
            if (postData is Map<dynamic, dynamic>) {
              newPosts.add({
                'id': postId,
                'userId': userId,
                ...Map<String, dynamic>.from(postData),
              });
            }
          });
        }
      });

      // Sort posts by timestamp (most recent first)
      newPosts
          .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

      setState(() {
        _posts = newPosts;
      });
    }
  }

  Future<void> _refreshFeed() async {
    await _loadFriendsPosts();
  }

  Future<void> _checkPendingRequests() async {
    DatabaseEvent event =
        await _database.child('users/$_currentUserId/friendRequests').once();
    if (event.snapshot.value != null) {
      setState(() {
        _hasPendingRequests = (event.snapshot.value as Map).isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InCampus',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationsPage()),
                  ).then((_) => _checkPendingRequests());
                },
              ),
              if (_hasPendingRequests)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chat, color: Colors.white),
            onPressed: () {
              // TODO: Implement chat page
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return PostCard(post: _posts[index], currentUserId: _currentUserId);
          },
        ),
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String currentUserId;

  PostCard({required this.post, required this.currentUserId});

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic> _userData = {};
  int _likeCount = 0;
  int _commentCount = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLikesAndComments();
    _checkIfLiked();
  }

  void _loadUserData() async {
    DatabaseEvent userEvent =
        await _database.child('users/${widget.post['userId']}').once();
    if (userEvent.snapshot.value != null) {
      setState(() {
        _userData = Map<String, dynamic>.from(userEvent.snapshot.value as Map);
      });
    }
  }

  void _loadLikesAndComments() async {
    DatabaseEvent likesEvent =
        await _database.child('likes/${widget.post['id']}').once();
    if (likesEvent.snapshot.value != null) {
      setState(() {
        _likeCount = (likesEvent.snapshot.value as Map).length;
      });
    }

    DatabaseEvent commentsEvent =
        await _database.child('comments/${widget.post['id']}').once();
    if (commentsEvent.snapshot.value != null) {
      setState(() {
        _commentCount = (commentsEvent.snapshot.value as Map).length;
      });
    }
  }

  void _checkIfLiked() async {
    DatabaseEvent likeEvent = await _database
        .child('likes/${widget.post['id']}/${widget.currentUserId}')
        .once();
    setState(() {
      _isLiked = likeEvent.snapshot.value != null;
    });
  }

  void _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    if (_isLiked) {
      await _database
          .child('likes/${widget.post['id']}/${widget.currentUserId}')
          .set(true);
    } else {
      await _database
          .child('likes/${widget.post['id']}/${widget.currentUserId}')
          .remove();
    }
  }

  void _openPostDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: widget.post['id'],
          post: widget.post,
          userId: widget.post['userId'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openUserProfile,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(_userData['profilePicture'] ?? ''),
              ),
              title: Text(_userData['name'] ?? 'Loading...'),
              subtitle: Text(_getTimeAgo(widget.post['timestamp'])),
            ),
          ),
          GestureDetector(
            onTap: _openPostDetail,
            onDoubleTap: _toggleLike,
            child: Image.network(
              widget.post['imageUrl'],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _openPostDetail,
                      child: Icon(Icons.comment_outlined),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('$_likeCount likes'),
                SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: _userData['name'] ?? 'Loading...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ${widget.post['description'] ?? ''}'),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: _openPostDetail,
                  child: Text(
                    'View all $_commentCount comments',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(int timestamp) {
    final now = DateTime.now();
    final difference =
        now.difference(DateTime.fromMillisecondsSinceEpoch(timestamp));

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  void _openUserProfile() {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (widget.post['userId'] == currentUserId) {
      // If it's the current user's post, navigate to ProfilePage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(),
        ),
      );
    } else {
      // If it's another user's post, navigate to UserProfilePage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(
            user: _userData,
            isFriend: true, // You might want to check this dynamically
            onFriendStatusChanged: (_, __) {}, // Implement this if needed
          ),
        ),
      );
    }
  }
}
