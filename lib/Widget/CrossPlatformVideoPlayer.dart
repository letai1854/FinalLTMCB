import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:path/path.dart' as path;

/// A video player that attempts to work across platforms
/// Falls back to alternative methods for platforms with limited support
class CrossPlatformVideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;
  final bool looping;

  const CrossPlatformVideoPlayer({
    Key? key,
    required this.videoPath,
    this.autoPlay = false,
    this.looping = false,
  }) : super(key: key);

  @override
  State<CrossPlatformVideoPlayer> createState() =>
      _CrossPlatformVideoPlayerState();
}

class _CrossPlatformVideoPlayerState extends State<CrossPlatformVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      print(
          "CrossPlatformVideoPlayer: Initializing player for ${widget.videoPath}");

      // Step 1: Validate and normalize the video path/URL
      String videoPath = widget.videoPath;

      // Normalize file paths for Windows
      if (!kIsWeb && !videoPath.startsWith('http')) {
        videoPath = videoPath.replaceAll('\\', '/');
        print("CrossPlatformVideoPlayer: Normalized path to $videoPath");
      }

      // Check if this might be a server URL
      bool isNetworkUrl = videoPath.startsWith('http://') ||
          videoPath.startsWith('https://') ||
          videoPath.startsWith('rtmp://') ||
          videoPath.startsWith('rtsp://');

      // Create the appropriate controller based on platform and path type
      if (kIsWeb) {
        print(
            "CrossPlatformVideoPlayer: Web platform detected, using network controller");
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(isNetworkUrl ? videoPath : Uri.file(videoPath).toString()),
        );
      } else if (isNetworkUrl) {
        print("CrossPlatformVideoPlayer: Using network URL");
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(videoPath));
      } else {
        print("CrossPlatformVideoPlayer: Using local file path");

        // Check if file exists
        final file = File(videoPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          print(
              "CrossPlatformVideoPlayer: File exists, size=${fileSize} bytes");

          if (fileSize == 0) {
            throw Exception('Video file is empty (0 bytes)');
          }
        } else {
          print(
              "CrossPlatformVideoPlayer: File doesn't exist, trying to find alternatives");
          final fileName = path.basename(videoPath);
          final possibleLocations = await _findPossibleFilePaths(fileName);

          if (possibleLocations.isNotEmpty) {
            videoPath = possibleLocations.first;
            print(
                "CrossPlatformVideoPlayer: Using alternative path: $videoPath");
          } else {
            throw Exception('Video file not found: $videoPath');
          }
        }

        // Use file controller with simpler approach
        _videoPlayerController = VideoPlayerController.file(File(videoPath));
      }

      // Use the simpler initialization pattern with .then() callback
      _videoPlayerController!.initialize().then((_) {
        if (mounted) {
          // Create Chewie controller after successful initialization
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: widget.autoPlay,
            looping: widget.looping,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 30),
                    SizedBox(height: 8),
                    Text(
                      'Error: $errorMessage',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    if (!kIsWeb)
                      TextButton(
                        onPressed: _openInExternalPlayer,
                        child: Text('Mở trong trình phát video'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
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
        print("CrossPlatformVideoPlayer: Initialization error: $error");
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = error.toString();
          });
        }
      });
    } catch (e) {
      print('CrossPlatformVideoPlayer: Error setting up video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // New method to find possible file paths for a video
  Future<List<String>> _findPossibleFilePaths(String fileName) async {
    List<String> possiblePaths = [];

    if (kIsWeb) return possiblePaths;

    try {
      // Check common video directories
      if (Platform.isAndroid) {
        final paths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Movies',
        ];

        for (final dir in paths) {
          final file = File('$dir/$fileName');
          if (await file.exists()) {
            possiblePaths.add(file.path);
          }
        }
      } else if (Platform.isWindows) {
        // Common Windows locations - adjust as needed
        final String home = Platform.environment['USERPROFILE'] ?? '';
        final paths = [
          '$home\\Downloads',
          '$home\\Videos',
          '$home\\Pictures',
        ];

        for (final dir in paths) {
          final file = File('$dir\\$fileName');
          if (await file.exists()) {
            possiblePaths.add(file.path.replaceAll('\\', '/'));
          }
        }
      }
    } catch (e) {
      print('Error finding alternative paths: $e');
    }

    return possiblePaths;
  }

  void _openInExternalPlayer() async {
    try {
      print(
          "CrossPlatformVideoPlayer: Attempting to open video in external player");
      final Uri fileUri = Uri.file(widget.videoPath);
      print("CrossPlatformVideoPlayer: URI = $fileUri");

      if (await url_launcher.canLaunchUrl(fileUri)) {
        print("CrossPlatformVideoPlayer: Launching URL...");
        await url_launcher.launchUrl(fileUri);
      } else {
        print("CrossPlatformVideoPlayer: Cannot launch URL");
        throw Exception('Could not launch video in external player');
      }
    } catch (e) {
      print('CrossPlatformVideoPlayer: Error opening external player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library, color: Colors.grey[700], size: 40),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  _errorMessage ?? 'Không thể tải video',
                  style: TextStyle(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!kIsWeb)
                TextButton(
                  onPressed: _openInExternalPlayer,
                  child: Text('Mở bằng phần mềm khác'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Đang tải video...')
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: 250,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _chewieController != null
            ? Chewie(controller: _chewieController!)
            : AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
      ),
    );
  }

  @override
  void dispose() {
    print("CrossPlatformVideoPlayer: Disposing controllers");
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
