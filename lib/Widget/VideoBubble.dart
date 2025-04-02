import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async'; // Add this import for TimeoutException
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:chewie/chewie.dart'; // Add chewie for better video controls

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
  ChewieController? _chewieController; // Add Chewie controller
  bool _isInitialized = false;
  bool _showControls = false;
  bool _hasError = false;
  String _errorMessage = "Không thể tải video";
  bool _isRetrying = false;
  bool _useFallback = false; // Use fallback player when default fails

  @override
  void initState() {
    super.initState();
    if (!widget.isLoading) {
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    try {
      // First check if the file exists (for non-web platforms)
      if (!kIsWeb) {
        try {
          final file = File(widget.videoPath);
          final exists = await file.exists();
          if (!exists) {
            setState(() {
              _hasError = true;
              _errorMessage = "Không tìm thấy file video";
            });
            return;
          }

          // Kiểm tra kích thước file
          final fileSize = await file.length();
          print("Video file size: $fileSize bytes");

          if (fileSize == 0) {
            setState(() {
              _hasError = true;
              _errorMessage = "File video rỗng";
            });
            return;
          }
        } catch (e) {
          print("Error checking video file: $e");
          // Continue anyway
        }
      }

      // Create the appropriate controller
      try {
        if (_controller != null) {
          await _controller!.dispose();
          _controller = null;
        }

        if (_chewieController != null) {
          _chewieController!.dispose();
          _chewieController = null;
        }

        print("Creating video controller for: ${widget.videoPath}");

        // Use different initialization approach based on platform
        if (_useFallback) {
          // Use a simplified approach when the default fails
          print("Using fallback video player initialization");
          _showFallbackVideoPlayer();
          return;
        }

        if (kIsWeb) {
          _controller =
              VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
        } else {
          // For Windows & other platforms, handle paths more carefully
          File file = File(widget.videoPath);
          if (await file.exists()) {
            try {
              _controller = VideoPlayerController.file(file);
            } catch (e) {
              print("Error with file controller, trying asset approach: $e");
              // If direct file fails, try network approach as fallback
              final uri = Uri.file(widget.videoPath);
              _controller = VideoPlayerController.networkUrl(uri);
            }
          } else {
            throw Exception("Video file not found: ${widget.videoPath}");
          }
        }

        // Initialize with a timeout
        print("Starting video initialization");
        bool initialized = false;

        try {
          await _controller!.initialize().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print("Video initialization timed out after 15 seconds");
              throw TimeoutException("Video initialization timed out");
            },
          );
          initialized = true;
        } catch (e) {
          print("Initialization failed: $e");
          initialized = false;
        }

        if (!initialized) {
          // Explicitly handle initialization failure
          throw Exception("Failed to initialize video controller");
        }

        // Create Chewie controller for better playback experience
        _chewieController = ChewieController(
          videoPlayerController: _controller!,
          autoPlay: false,
          looping: false,
          aspectRatio: _controller!.value.aspectRatio,
          allowMuting: true,
          allowPlaybackSpeedChanging: false,
          showControls: false, // We'll use our own controls
        );

        // Set volume if initialization succeeded
        if (initialized) {
          await _controller!.setVolume(1.0);
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
        }
      } catch (e) {
        print("Error creating video controller: $e");

        if (!_useFallback) {
          // Try with fallback approach
          setState(() {
            _useFallback = true;
          });
          _initializeController();
          return;
        }

        throw e;
      }
    } catch (e) {
      print("Final error initializing video player: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          if (e.toString().contains("UnimplementedError")) {
            _errorMessage = "Video không được hỗ trợ trên thiết bị này";
          } else if (e.toString().contains("TimeoutException")) {
            _errorMessage = "Tải video quá lâu";
          } else {
            _errorMessage =
                "Lỗi khi tải video: ${e.toString().split('\n').first}";
          }
        });
      }
    }
  }

  // Show a simplified fallback video player (thumbnail with play button)
  void _showFallbackVideoPlayer() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _isInitialized = true;
      });
    }
  }

  @override
  void didUpdateWidget(VideoBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath ||
        (oldWidget.isLoading && !widget.isLoading)) {
      _disposeController();
      _initializeController();
    }
  }

  void _disposeController() {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _tryOpenExternalVideo() {
    if (!kIsWeb) {
      // Show a dialog with options for the user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Tùy chọn video"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Không thể phát video trong ứng dụng."),
              SizedBox(height: 8),
              Text("Đường dẫn: ${widget.videoPath}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              SizedBox(height: 12),
              Text("Bạn muốn thực hiện thao tác nào?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isRetrying = true;
                });
                _initializeController().then((_) {
                  if (mounted) {
                    setState(() {
                      _isRetrying = false;
                    });
                  }
                });
              },
              child: Text("Thử lại"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Mở video trong chế độ toàn màn hình
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        iconTheme: IconThemeData(color: Colors.white),
                        title: Text("Video",
                            style: TextStyle(color: Colors.white)),
                      ),
                      body: Center(
                        child: Text(
                          "Video sẽ được xử lý bởi server",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: Text("Xem toàn màn hình"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.red.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.isLoading
            ? _buildLoadingView()
            : _hasError
                ? _buildErrorView()
                : _isInitialized && _controller != null
                    ? _buildVideoPlayer()
                    : _buildInitializingView(),
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
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 8),
          Text(
            "Đang xử lý video...",
            style: TextStyle(color: Colors.red.shade700),
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
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 8),
          Text(
            "Đang tải video...",
            style: TextStyle(color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final fileName = path.basename(widget.videoPath);
    final shortName =
        fileName.length > 20 ? '${fileName.substring(0, 17)}...' : fileName;

    return InkWell(
      onTap: _tryOpenExternalVideo,
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
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              "Nhấn để mở",
              style: TextStyle(
                color: Colors.blue,
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
    if (_controller == null || _useFallback) {
      return _buildFallbackVideoPlayer();
    }

    // Check if we have a valid controller and it's initialized
    if (!_controller!.value.isInitialized) {
      return _buildInitializingView();
    }

    // Use Chewie for better video playback if available
    if (_chewieController != null) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Container with fixed size to prevent layout jumps
            Container(
              color: Colors.black,
              width: double.infinity,
              height: 180,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                ),
              ),
            ),

            // Custom overlay controls if needed
            if (_showControls)
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () {
                    _controller!.pause();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FullscreenVideoPlayer(
                          videoPath: widget.videoPath,
                        ),
                      ),
                    );
                  },
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
        ),
      );
    }

    // Fallback to basic player if Chewie isn't available
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video container
          Container(
            color: Colors.black,
            width: double.infinity,
            height: 180,
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

          // Play/pause button
          if (_showControls || !_controller!.value.isPlaying)
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

          // Nút toàn màn hình
          if (_showControls)
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () {
                  // Tạm dừng video trước khi mở toàn màn hình
                  _controller!.pause();

                  // Mở video trong chế độ toàn màn hình
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          FullscreenVideoPlayer(videoPath: widget.videoPath),
                    ),
                  );
                },
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

          // Video progress indicator
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(_controller!.value.position),
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        colors: VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.red.shade100,
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_controller!.value.duration),
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Fallback player shows a thumbnail with play button
  Widget _buildFallbackVideoPlayer() {
    return GestureDetector(
      onTap: () => _tryOpenExternalVideo(),
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail or placeholder
            Container(
              color: Colors.grey.shade800,
              child: Center(
                child: Icon(
                  Icons.video_file,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

            // Play button overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),

            // Info text
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Nhấn để mở video",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
      await _controller.setVolume(1.0);

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
                ? CircularProgressIndicator(color: Colors.red)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              backgroundColor: Colors.red,
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
