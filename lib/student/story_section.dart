import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'package:intl/intl.dart';

class StorySection extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final String currentUserId;
  final VoidCallback onStoryAdded;

  // Define dark theme colors
  final Color _primaryColor = Colors.black;
  final Color _accentColor = Colors.blue[700]!;
  final Color _backgroundColor = Color(0xFF121212);
  final Color _surfaceColor = Color(0xFF1E1E1E);
  final Color _onSurfaceColor = Colors.white;

  StorySection({
    required this.stories,
    required this.currentUserId,
    required this.onStoryAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildStoryItem(
              context,
              child: _buildAddStoryButton(context),
              label: 'Your Story',
            );
          } else {
            final story = stories[index - 1];
            return _buildStoryItem(
              context,
              child: _buildStoryAvatar(context, story),
              label: story['username'] ?? '',
            );
          }
        },
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context,
      {required Widget child, required String label}) {
    return Container(
      width: 70, // Reduced width
      padding: EdgeInsets.symmetric(horizontal: 2), // Reduced padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          SizedBox(height: 2), // Reduced spacing
          Text(
            label,
            style:
                TextStyle(color: _onSurfaceColor, fontSize: 9), // Smaller font
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddStoryOptions(context),
      child: Container(
        width: 60, // Reduced size
        height: 60, // Reduced size
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _accentColor, width: 2),
          color: _surfaceColor,
        ),
        child: Icon(Icons.add,
            color: _accentColor, size: 30), // Adjusted icon size
      ),
    );
  }

  void _showAddStoryOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo, color: _onSurfaceColor),
                title: Text('Upload Image',
                    style: TextStyle(color: _onSurfaceColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(context, ImageSource.gallery, isVideo: false);
                },
              ),
              ListTile(
                leading: Icon(Icons.video_library, color: _onSurfaceColor),
                title: Text('Upload Video',
                    style: TextStyle(color: _onSurfaceColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(context, ImageSource.gallery, isVideo: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMedia(BuildContext context, ImageSource source,
      {required bool isVideo}) async {
    final ImagePicker _picker = ImagePicker();
    try {
      XFile? pickedFile;
      if (isVideo) {
        pickedFile = await _picker.pickVideo(source: source);
      } else {
        pickedFile = await _picker.pickImage(source: source);
      }

      if (pickedFile != null) {
        _uploadStory(context, pickedFile, isVideo);
      }
    } catch (e) {
      print("Error picking media: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  Future<void> _uploadStory(
      BuildContext context, XFile file, bool isVideo) async {
    try {
      final User currentUser = FirebaseAuth.instance.currentUser!;
      final String userId = currentUser.uid;
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('stories/$userId/$fileName');

      // Upload the main file
      await storageRef.putFile(File(file.path));
      final String downloadUrl = await storageRef.getDownloadURL();

      // Generate and upload thumbnail
      String thumbnailUrl = '';
      if (isVideo) {
        final thumbnailFile = await VideoCompress.getFileThumbnail(file.path);
        final thumbnailRef = FirebaseStorage.instance
            .ref()
            .child('stories/$userId/thumbnails/$fileName.jpg');
        await thumbnailRef.putFile(thumbnailFile);
        thumbnailUrl = await thumbnailRef.getDownloadURL();
      } else {
        thumbnailUrl =
            downloadUrl; // For images, use the same URL for thumbnail
      }

      final DatabaseReference dbRef =
          FirebaseDatabase.instance.ref().child('stories/$userId').push();
      await dbRef.set({
        'mediaUrl': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
        'type': isVideo ? 'video' : 'image',
        'timestamp': ServerValue.timestamp,
        'username': currentUser.displayName ?? 'Anonymous',
        'userProfilePicture': currentUser.photoURL ?? '',
      });

      // Call the callback to notify that a new story has been added
      onStoryAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Story uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading story: $e')),
      );
    }
  }

  Widget _buildStoryAvatar(BuildContext context, Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () => _viewStory(context, story),
      child: Container(
        width: 60, // Reduced size
        height: 60, // Reduced size
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _accentColor, width: 2),
          image: DecorationImage(
            image: NetworkImage(story['thumbnailUrl']),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  void _viewStory(BuildContext context, Map<String, dynamic> story) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FullScreenStory(story: story),
    ));
  }
}

class FullScreenStory extends StatefulWidget {
  final Map<String, dynamic> story;

  FullScreenStory({required this.story});

  @override
  _FullScreenStoryState createState() => _FullScreenStoryState();
}

class _FullScreenStoryState extends State<FullScreenStory> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.story['type'] == 'video') {
      _videoController = VideoPlayerController.network(widget.story['mediaUrl'])
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: widget.story['type'] == 'video'
                    ? _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : CircularProgressIndicator()
                    : Image.network(widget.story['mediaUrl']),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        NetworkImage(widget.story['userProfilePicture'] ?? ''),
                    radius: 20,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.story['username'] ?? 'Anonymous',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatTimestamp(widget.story['timestamp']),
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }
}
