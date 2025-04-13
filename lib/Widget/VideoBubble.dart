import 'package:finalltmcb/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:chewie/chewie.dart';
// Add media_kit imports for Windows
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoBubble extends StatefulWidget {
  final String videoPath;
  final bool isMe;
  final bool isLoading;

  const VideoBubble({
    Key? key,
    required this.videoPath,
    required this.isMe,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<VideoBubble> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _hasError = false;
  String _errorMessage = "Không thể tải video";

  // Add media_kit components for Windows
  Player? _mediaKitPlayer;
  VideoController? _mediaKitVideoController;
  bool _useMediaKit = false;

  // Thêm biến để theo dõi trạng thái âm thanh
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isLoading) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    if (widget.videoPath.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = "Đường dẫn video không hợp lệ";
      });
      return;
    }

    try {
      // Dispose any existing controllers
      _disposeControllers();

      // Check file existence and size first for non-web platforms
      if (!kIsWeb) {
        try {
          String normalizedPath = widget.videoPath.replaceAll('\\', '/');
          final File videoFile = File(normalizedPath);

          if (!videoFile.existsSync()) {
            print("VideoBubble: File does not exist: $normalizedPath");
            setState(() {
              _hasError = true;
              _errorMessage = "Không tìm thấy file video";
            });
            return;
          }

          final fileSize = videoFile.lengthSync();
          if (fileSize == 0) {
            print("VideoBubble: Empty file: $normalizedPath");
            setState(() {
              _hasError = true;
              _errorMessage = "File video rỗng";
            });
            return;
          }

          print("VideoBubble: Video file verified, size: $fileSize bytes");
        } catch (e) {
          print("VideoBubble: Error checking file: $e");
          // Continue with initialization anyway
        }
      }

      // Choose which player implementation to use based on platform
      if (kIsWeb) {
        _initializeStandardPlayer();
      } else if (Platform.isWindows) {
        _initializeMediaKitPlayer();
      } else {
        _initializeStandardPlayer();
      }
    } catch (e) {
      print("VideoBubble: Error creating controller: $e");
      setState(() {
        _hasError = true;
        _errorMessage =
            "Lỗi tạo trình phát video: ${e.toString().split('\n').first}";
      });
    }
  }

  // Initialize standard video_player for non-Windows platforms
  void _initializeStandardPlayer() {
    print("Using standard video player for: ${widget.videoPath}");

    try {
      if (kIsWeb) {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        String normalizedPath = widget.videoPath.replaceAll('\\', '/');
        _controller = VideoPlayerController.file(File(normalizedPath));
      }

      _controller!.initialize().then((_) {
        print("Standard video player initialized successfully");
        if (mounted) {
          _chewieController = ChewieController(
            videoPlayerController: _controller!,
            aspectRatio: _controller!.value.aspectRatio,
            autoPlay: false,
            looping: false,
            showControls: true,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    Text(errorMessage, style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          );
          setState(() {
            _useMediaKit = false;
          });
        }
      }).catchError((error) {
        print("Standard video player initialization error: $error");
        if (mounted) {
          // If standard player fails, try media_kit on Windows
          if (Platform.isWindows) {
            _initializeMediaKitPlayer();
            return;
          }

          setState(() {
            _hasError = true;
            _errorMessage =
                "Không thể tải video: ${error.toString().split('\n').first}";
          });
        }
      });
    } catch (e) {
      print("Error creating standard video player: $e");
      // Try media_kit on Windows if standard player fails
      if (Platform.isWindows) {
        _initializeMediaKitPlayer();
      } else {
        throw e;
      }
    }
  }

  // Initialize media_kit player for Windows
  void _initializeMediaKitPlayer() {
    print("Using MediaKit player for Windows: ${widget.videoPath}");

    try {
      String normalizedPath = widget.videoPath.replaceAll('\\', '/');

      // Create and initialize the player
      _mediaKitPlayer = Player();
      _mediaKitVideoController = VideoController(_mediaKitPlayer!);
      _mediaKitPlayer!.setVolume(0);

      // Open the media file
      _mediaKitPlayer!.open(Media(normalizedPath));

      setState(() {
        _useMediaKit = true;
      });

      print("MediaKit player initialized successfully");
    } catch (e) {
      print("MediaKit initialization error: $e");
      setState(() {
        _hasError = true;
        _errorMessage =
            "Windows không thể phát video này: ${e.toString().split('\n').first}";
      });
    }
  }

  @override
  void didUpdateWidget(VideoBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath ||
        (oldWidget.isLoading && !widget.isLoading)) {
      _initializeVideo();
    }
  }

  void _disposeControllers() {
    // Dispose standard controllers
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }

    // Dispose media_kit controllers
    if (_mediaKitPlayer != null) {
      _mediaKitPlayer!.dispose();
      _mediaKitPlayer = null;
      _mediaKitVideoController = null;
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _openFullscreenVideo() {
    if (_controller != null) {
      _controller!.pause();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              FullscreenVideoPlayer(videoPath: widget.videoPath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.25,
        maxHeight: 360,
      ),
      decoration: BoxDecoration(
        color: widget.isMe ? AppColors.messengerBlue : AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.isLoading
            ? _buildLoadingView()
            : _hasError
                ? _buildErrorView()
                : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.black.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 8),
          Text(
            "Đang xử lý video...",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final fileName = path.basename(widget.videoPath);
    final shortName =
        fileName.length > 20 ? '${fileName.substring(0, 17)}...' : fileName;
    final extension = path.extension(widget.videoPath).toLowerCase();

    return InkWell(
      onTap: _openFullscreenVideo,
      child: Container(
        width: 200,
        height: 150,
        color: Colors.black.withOpacity(0.1),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              shortName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            if (Platform.isWindows && !['.mp4', '.webm'].contains(extension))
              Text(
                "Định dạng: $extension (không hỗ trợ)",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                ),
              ),
            SizedBox(height: 4),
            Text(
              "Nhấn để mở",
              style: TextStyle(
                color: AppColors.messengerBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    // Use Media Kit for Windows
    if (_useMediaKit &&
        _mediaKitPlayer != null &&
        _mediaKitVideoController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event.logicalKey == LogicalKeyboardKey.keyM) {
                setState(() {
                  _isMuted = !_isMuted;
                  _mediaKitPlayer?.setVolume(_isMuted ? 0 : 100);
                });
              }
            },
            child: Video(
              controller: _mediaKitVideoController!,
              controls: MaterialVideoControls,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isMuted = !_isMuted;
                  _mediaKitPlayer?.setVolume(_isMuted ? 0 : 100);
                });
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () {
                // Mở trong chế độ toàn màn hình
                _mediaKitPlayer!.pause();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        MediaKitFullscreenPlayer(videoPath: widget.videoPath),
                  ),
                );
              },
              // child: Container(
              //   padding: EdgeInsets.all(4),
              //   decoration: BoxDecoration(
              //     color: Colors.black.withOpacity(0.6),
              //     borderRadius: BorderRadius.circular(4),
              //   ),
              //   child: Icon(
              //     Icons.fullscreen,
              //     color: Colors.white,
              //     size: 20,
              //   ),
              // ),
            ),
          ),
        ],
      );
    }

    // Check if we have a valid controller and it's initialized
    if (_controller == null) {
      return _buildInitializingView();
    }

    if (!_controller!.value.isInitialized) {
      return _buildInitializingView();
    }

    // Return Chewie player if available
    if (_chewieController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event.logicalKey == LogicalKeyboardKey.keyM) {
                setState(() {
                  _isMuted = !_isMuted;
                  _controller?.setVolume(_isMuted ? 0 : 1);
                });
              }
            },
            child: Chewie(controller: _chewieController!),
          ),
          Positioned(
            top: 8,
            right: 40, // Đặt bên phải nút fullscreen
            child: InkWell(
              onTap: () {
                setState(() {
                  _isMuted = !_isMuted;
                  _controller?.setVolume(_isMuted ? 0 : 1);
                });
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: _openFullscreenVideo,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Fallback to basic VideoPlayer if no Chewie
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          IconButton(
            icon: Icon(
              _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
            onPressed: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInitializingView() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.black.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.messengerBlue),
          SizedBox(height: 8),
          Text(
            "Đang tải video...",
            style: TextStyle(color: AppColors.messengerBlue),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Thêm widget cho chế độ xem video toàn màn hình
class FullscreenVideoPlayer extends StatefulWidget {
  final String videoPath;

  const FullscreenVideoPlayer({Key? key, required this.videoPath})
      : super(key: key);

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      if (kIsWeb) {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _controller = VideoPlayerController.file(File(widget.videoPath));
      }

      await _controller.initialize();
      await _controller.setVolume(0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Tự động phát khi sẵn sàng
        _controller.play();
      }
    } catch (e) {
      print("Error initializing fullscreen video: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
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
                ? CircularProgressIndicator(color: AppColors.messengerBlue)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              backgroundColor: AppColors.messengerBlue,
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

// Add a new class for MediaKit fullscreen player
class MediaKitFullscreenPlayer extends StatefulWidget {
  final String videoPath;

  const MediaKitFullscreenPlayer({Key? key, required this.videoPath})
      : super(key: key);

  @override
  State<MediaKitFullscreenPlayer> createState() =>
      _MediaKitFullscreenPlayerState();
}

class _MediaKitFullscreenPlayerState extends State<MediaKitFullscreenPlayer> {
  late Player _player;
  late VideoController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      String normalizedPath = widget.videoPath.replaceAll('\\', '/');
      _player = Player();
      _controller = VideoController(_player);
      _player.setVolume(0);
      _player.open(Media(normalizedPath));
      _player.play();
    } catch (e) {
      print("MediaKit fullscreen error: $e");
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
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
      body: _hasError
          ? Center(
              child: Text("Không thể phát video",
                  style: TextStyle(color: Colors.white)))
          : Center(
              child: Video(
                controller: _controller,
                controls: MaterialVideoControls,
              ),
            ),
    );
  }
}
