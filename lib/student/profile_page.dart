import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:incampus/student/edit_profile_page.dart';
import 'package:incampus/student/post_detail_screen.dart';
import 'package:video_player/video_player.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _reels = [];
  Map<String, dynamic> _userProfile = {};

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
    _loadUserProfile();
    _loadUserContent();
  }

  void _loadUserProfile() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/$userId');
      userRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            _userProfile =
                Map<String, dynamic>.from(event.snapshot.value as Map);
          });
        }
      });
    }
  }

  void _loadUserContent() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DatabaseReference postsRef =
          FirebaseDatabase.instance.ref('posts/$userId');
      DatabaseReference reelsRef =
          FirebaseDatabase.instance.ref('reels/$userId');

      postsRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            _posts = (event.snapshot.value as Map)
                .entries
                .map((e) => {
                      'id': e.key,
                      ...Map<String, dynamic>.from(e.value as Map),
                    })
                .toList();
          });
        }
      });

      reelsRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            _reels = (event.snapshot.value as Map)
                .entries
                .map((e) => {
                      'id': e.key,
                      ...Map<String, dynamic>.from(e.value as Map),
                    })
                .toList();
          });
        }
      });
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
        tabBarTheme: TabBarTheme(
          labelColor: _accentColor,
          unselectedLabelColor: _onSurfaceColor,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_userProfile['username'] ?? 'Profile',
              style: TextStyle(color: _onSurfaceColor)),
          actions: [
            IconButton(
              icon: Icon(Icons.menu, color: _onSurfaceColor),
              onPressed: () {
                // TODO: Implement menu options
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align children to the start (left)
          children: [
            _buildProfileHeader(),
            _buildProfileStats(),
            _buildBio(), // Moved up in the hierarchy
            _buildEditProfileButton(),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.grid_on)),
                Tab(icon: Icon(Icons.play_circle_outline)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsGrid(),
                  _buildReelsGrid(),
                ],
              ),
            ),
          ],
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
            backgroundImage: NetworkImage(_userProfile['profilePicture'] ??
                'https://via.placeholder.com/150'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile['name'] ?? 'User Name',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _onSurfaceColor),
                ),
                Text(_userProfile['email'] ?? 'email@example.com',
                    style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn(_posts.length.toString(), 'Posts'),
        _buildStatColumn(
            _userProfile['followers']?.toString() ?? '0', 'Followers'),
        _buildStatColumn(
            _userProfile['following']?.toString() ?? '0', 'Following'),
      ],
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _onSurfaceColor),
        ),
        Text(label, style: TextStyle(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildBio() {
    return Container(
      width: double.infinity, // Ensure the container takes full width
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        _userProfile['bio'] ?? 'No bio available',
        style: TextStyle(color: _onSurfaceColor),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    EditProfilePage(userProfile: _userProfile)),
          );
          if (result == true) {
            // Refresh the profile data if changes were made
            _loadUserProfile();
          }
        },
        child: Text('Edit Profile'),
        style: ElevatedButton.styleFrom(
          foregroundColor: _onSurfaceColor,
          backgroundColor: _accentColor,
          minimumSize: Size(double.infinity, 36),
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
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
                  userId: FirebaseAuth.instance.currentUser?.uid ??
                      '', // Add this line
                ),
              ),
            );
          },
          child: Image.network(
            _posts[index]['imageUrl'],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _playReel(_reels[index]['videoUrl']),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _reels[index]['thumbnailUrl'] ?? '',
                fit: BoxFit.cover,
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

  void _playReel(String videoUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Theme(
        data: ThemeData.dark().copyWith(
          primaryColor: _primaryColor,
          scaffoldBackgroundColor: _backgroundColor,
        ),
        child: Scaffold(
          appBar: AppBar(
              title: Text('Reel', style: TextStyle(color: _onSurfaceColor))),
          body: Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: VideoPlayer(VideoPlayerController.network(videoUrl)
                ..initialize().then((_) {
                  setState(() {});
                })),
            ),
          ),
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
