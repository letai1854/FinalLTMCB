import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final String videoPath;

  const FullscreenVideoPlayer({Key? key, required this.videoPath})
      : super(key: key);

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      print("FullscreenPlayer: Initializing video: ${widget.videoPath}");

      // Normalize path and create appropriate controller based on platform
      String normalizedPath = widget.videoPath.replaceAll('\\', '/');

      if (kIsWeb) {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else if (Platform.isWindows) {
        print("FullscreenPlayer: Initializing for Windows");
        _controller = VideoPlayerController.file(File(normalizedPath));
      } else if (Platform.isAndroid) {
        print("FullscreenPlayer: Initializing for Android");
        _controller = VideoPlayerController.file(File(widget.videoPath));
      } else {
        _controller = VideoPlayerController.file(File(normalizedPath));
      }

      // Use simple initialization approach
      _controller.initialize().then((_) {
        print("FullscreenPlayer: Video initialized successfully");
        if (mounted) {
          _chewieController = ChewieController(
            videoPlayerController: _controller,
            autoPlay: true,
            looping: false,
            aspectRatio: _controller.value.aspectRatio,
            showControls: true,
            allowFullScreen: true,
            allowMuting: true,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 32),
                    SizedBox(height: 8),
                    Text("Lỗi: $errorMessage",
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Quay lại"),
                    )
                  ],
                ),
              );
            },
          );

          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        print("FullscreenPlayer: Error initializing: $error");
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
      print("FullscreenPlayer: Error creating player: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Video", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: _hasError
            ? Text("Không thể phát video",
                style: TextStyle(color: Colors.white))
            : !_isInitialized
                ? CircularProgressIndicator(color: Colors.red)
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
      ),
    );
  }
}
