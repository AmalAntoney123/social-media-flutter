import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

class ReelDetailScreen extends StatefulWidget {
  final String reelId;
  final String videoUrl;
  final String userName;
  final String musicName;
  final String reelDescription;
  final String profileUrl;

  ReelDetailScreen({
    required this.reelId,
    required this.videoUrl,
    required this.userName,
    this.musicName = '',
    this.reelDescription = '',
    this.profileUrl = '',
  });

  @override
  _ReelDetailScreenState createState() => _ReelDetailScreenState();
}

class _ReelDetailScreenState extends State<ReelDetailScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = true;
  bool isLiked = false;
  int likeCount = 0;
  List<Map<String, dynamic>> comments = [];
  String userName = '';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
    _loadReelData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadReelData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DatabaseReference reelRef =
          FirebaseDatabase.instance.ref('reels/$userId/${widget.reelId}');
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/$userId');

      try {
        DatabaseEvent reelEvent = await reelRef.once();
        DatabaseEvent userEvent = await userRef.once();

        Map<dynamic, dynamic>? reelData = reelEvent.snapshot.value as Map?;
        Map<dynamic, dynamic>? userData = userEvent.snapshot.value as Map?;

        if (reelData != null && userData != null) {
          setState(() {
            likeCount = reelData['likes'] ?? 0;
            isLiked =
                (reelData['likedBy'] as Map?)?.containsKey(userId) ?? false;

            if (reelData['comments'] != null) {
              comments = (reelData['comments'] as Map)
                  .entries
                  .map((e) => {
                        'id': e.key,
                        ...Map<String, dynamic>.from(e.value as Map),
                      })
                  .toList();
            }

            userName = userData['name'] ?? '';
          });
        }
      } catch (e) {
        print('Error loading reel data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video player
          GestureDetector(
            onTap: () {
              setState(() {
                _isPlaying = !_isPlaying;
                _isPlaying ? _controller.play() : _controller.pause();
              });
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : Center(child: CircularProgressIndicator()),
            ),
          ),
          // Overlay content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Reel',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(width: 48), // Placeholder for symmetry
                  ],
                ),
                // Bottom content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Reel info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.userName,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (widget.reelDescription.isNotEmpty)
                              Text(
                                widget.reelDescription,
                                style: TextStyle(color: Colors.white),
                              ),
                            if (widget.musicName.isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.music_note,
                                      color: Colors.white, size: 15),
                                  Text(
                                    widget.musicName,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Like and comment buttons
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInteractionButton(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.white,
                            count: likeCount,
                            onTap: () => _handleLike(context),
                          ),
                          SizedBox(height: 16),
                          _buildInteractionButton(
                            icon: Icons.comment,
                            color: Colors.white,
                            count: comments.length,
                            onTap: () => _showComments(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 32),
          onPressed: onTap,
        ),
        Text(
          '$count',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  void _handleLike(BuildContext context) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DatabaseReference reelRef =
          FirebaseDatabase.instance.ref('reels/$userId/${widget.reelId}');

      try {
        DatabaseEvent event = await reelRef.once();
        Map<dynamic, dynamic>? reelData = event.snapshot.value as Map?;

        if (reelData != null) {
          Map<String, dynamic> likedBy =
              Map<String, dynamic>.from(reelData['likedBy'] ?? {});

          if (likedBy.containsKey(userId)) {
            likedBy.remove(userId);
            await reelRef.update({
              'likes': ServerValue.increment(-1),
              'likedBy': likedBy,
            });
            setState(() {
              isLiked = false;
              likeCount--;
            });
          } else {
            likedBy[userId] = true;
            await reelRef.update({
              'likes': ServerValue.increment(1),
              'likedBy': likedBy,
            });
            setState(() {
              isLiked = true;
              likeCount++;
            });
          }
        }
      } catch (e) {
        print('Error updating like count: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like. Please try again.')),
        );
      }
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(comments[index]['comment']),
                      subtitle: Text('User: ${comments[index]['userId']}'),
                    );
                  },
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      // Implement adding a new comment
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
