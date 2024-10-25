import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelDetailScreen extends StatefulWidget {
  final String videoUrl;

  ReelDetailScreen({required this.videoUrl});

  @override
  _ReelDetailScreenState createState() => _ReelDetailScreenState();
}

class _ReelDetailScreenState extends State<ReelDetailScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : CircularProgressIndicator(),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                  _isPlaying = !_isPlaying;
                });
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
