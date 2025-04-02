import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioBubble extends StatefulWidget {
  final String audioSource; // Can be base64 or file path
  final bool isMe;
  final DateTime timestamp;
  final bool isPath; // Flag to indicate if audioSource is a path or base64

  const AudioBubble({
    Key? key,
    required this.audioSource,
    required this.isMe,
    required this.timestamp,
    this.isPath = false,
  }) : super(key: key);

  @override
  State<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<AudioBubble> {
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  bool _loadError = false;
  String _errorMessage = '';
  bool _hasInitialized = false; // Track if player has been initialized

  @override
  void initState() {
    super.initState();
    print("🎵 AudioBubble initializing...");
    // Configure audio player first, then setup
    _configureAudioPlayer();
    // Delay setup slightly to avoid blocking UI
    Future.microtask(() => _setupAudioPlayer());
  }

  @override
  void dispose() {
    print("🎵 AudioBubble disposing...");
    _audioPlayer.dispose();
    super.dispose();
  }

  // Add configuration specific to mobile devices
  Future<void> _configureAudioPlayer() async {
    try {
      // Set global configuration for better mobile playback
      await _audioPlayer.setReleaseMode(
          ReleaseMode.stop); // Using stop mode to allow manual replay

      // Set audio player mode for better mobile compatibility
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);

      print("🎵 Audio player configured for mobile playback");
    } catch (e) {
      print("🎵 Error configuring audio player: $e");
    }
  }

  Future<void> _setupAudioPlayer() async {
    if (_hasInitialized) return; // Prevent multiple initializations

    try {
      print("🎵 Setting up audio player...");
      _hasInitialized = true;

      // Set up listeners before loading audio to catch all events
      _audioPlayer.onDurationChanged.listen((newDuration) {
        print("🎵 Duration changed: $newDuration");
        if (mounted) {
          setState(() {
            _duration = newDuration;
            _isLoading = false;
          });
        }
      });

      _audioPlayer.onPositionChanged.listen((newPosition) {
        if (mounted) {
          setState(() => _position = newPosition);
        }
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        print("🎵 Playback completed");
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero; // Reset position for replay
          });
        }
      });

      _audioPlayer.onPlayerStateChanged.listen((state) {
        print("🎵 Player state changed: $state");
        if (mounted) {
          if (state == PlayerState.playing) {
            setState(() => _isPlaying = true);
          } else if (state == PlayerState.paused ||
              state == PlayerState.stopped) {
            setState(() => _isPlaying = false);
          }
        }
      });

      // Set source based on whether we have a file path or base64
      if (widget.isPath) {
        // File path source
        print("🎵 Using file path: ${widget.audioSource}");
        final file = File(widget.audioSource);

        if (await file.exists()) {
          final fileSize = await file.length();
          print("🎵 File exists, size: $fileSize bytes");

          // Try to set the source with more forceful approach for mobile
          try {
            // Reset player first
            await _audioPlayer.stop();

            // On mobile, try using the file source method
            if (!kIsWeb) {
              await _audioPlayer.setSourceUrl(widget.audioSource);
              print("🎵 Set source URL successfully (file:// path)");
            } else {
              await _audioPlayer.setSourceDeviceFile(widget.audioSource);
              print("🎵 Set source device file successfully");
            }
          } catch (e) {
            print("🎵 ERROR setting device file source: $e");
            // Try alternative method with more robust error handling
            try {
              final bytes = await file.readAsBytes();
              print("🎵 Read ${bytes.length} bytes from file");
              await _audioPlayer.setSourceBytes(bytes);
              print("🎵 Fallback to bytes source successful");
            } catch (e2) {
              print("🎵 Bytes fallback also failed: $e2");
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadError = true;
                  _errorMessage = 'Cannot load audio file';
                });
              }
              return;
            }
          }
        } else {
          print("🎵 ERROR: File not found at path: ${widget.audioSource}");
          if (mounted) {
            setState(() {
              _isLoading = false;
              _loadError = true;
              _errorMessage = 'Audio file not found';
            });
          }
          return;
        }
      } else {
        // Base64 source
        try {
          print("🎵 Using base64 data (length: ${widget.audioSource.length})");
          final Uint8List audioBytes = base64Decode(widget.audioSource);
          print("🎵 Decoded base64, byte length: ${audioBytes.length}");
          await _audioPlayer.setSourceBytes(audioBytes);
          print("🎵 Set bytes source successfully");
        } catch (e) {
          print("🎵 ERROR setting base64 source: $e");
          if (mounted) {
            setState(() {
              _isLoading = false;
              _loadError = true;
              _errorMessage = 'Invalid audio data';
            });
          }
          return;
        }
      }

      // Set a timeout if duration never gets reported
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && _isLoading) {
          print("🎵 Timeout waiting for duration, assuming small audio file");
          setState(() {
            _isLoading = false;
            if (_duration == Duration.zero) {
              // Just set a fake duration so it's not zero
              _duration = Duration(seconds: 1);
            }
          });
        }
      });

      print("🎵 Audio player setup complete");
    } catch (e) {
      print('🎵 Error in setupAudioPlayer: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = true;
          _errorMessage = 'Error loading audio';
        });
      }
    }
  }

  Future<void> _playPause() async {
    if (_isLoading) return;

    if (_loadError) {
      print("🎵 Cannot play due to load error: $_errorMessage");
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        print("🎵 Audio paused");
        setState(() => _isPlaying = false);
      } else {
        // Always stop and seek to beginning for consistent replay behavior
        await _audioPlayer.stop();
        await _audioPlayer.seek(Duration.zero);

        // Resume playback from the beginning
        await _audioPlayer.resume();

        print("🎵 Audio playing from start");
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      print('🎵 Error playing/pausing audio: $e');
      // Try to recover by resetting player
      _resetAudioPlayer();
    }
  }

  // Add a recovery method to reset player state
  Future<void> _resetAudioPlayer() async {
    print("🎵 Resetting audio player due to error");
    try {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
      // Re-configure if needed
      await _configureAudioPlayer();
    } catch (e) {
      print("🎵 Error during player reset: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Làm cho bubble thậm chí nhỏ gọn hơn nữa
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.red.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button - còn nhỏ hơn nữa
          _loadError
              ? Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 18,
                )
              : IconButton(
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red.shade300,
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.red,
                          size: 18,
                        ),
                  onPressed: _playPause,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                ),
          const SizedBox(width: 2),

          // Phần visualization và thời gian - giảm kích thước
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audio visualization - giảm chiều cao
                Container(
                  height: 16, // Giảm chiều cao
                  decoration: BoxDecoration(
                    color:
                        _loadError ? Colors.red.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _loadError
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              fontSize: 7.0,
                              color: Colors.red.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Progress indicator
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _duration.inMilliseconds > 0
                                  ? _position.inMilliseconds /
                                      _duration.inMilliseconds
                                  : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade200,
                                      Colors.red.shade300
                                    ],
                                  ),
                                ),
                                height: double.infinity,
                              ),
                            ),

                            // Đơn giản hóa pattern - ít thanh hơn, gọn hơn
                            Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  6, // Giảm số lượng thanh
                                  (index) => Container(
                                    width: 1.0,
                                    height: (index % 3 + 1) * 2.0 +
                                        2.0, // Giảm chiều cao
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                // Hiển thị thời gian - fontsize nhỏ hơn
                Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: Text(
                    _loadError
                        ? 'Error'
                        : '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(
                      fontSize: 7.0, // Giảm font size
                      color: _loadError
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
