import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioRecorderWidget extends StatefulWidget {
  final Function(String) onAudioSaved;
  final VoidCallback onCancel;

  const AudioRecorderWidget({
    Key? key,
    required this.onAudioSaved,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  // Create the recorder instance with the factory method for version 6.0.0
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;
  String? _recordingPath;
  bool _isInitialized = false;

  // Add animation controller for the pulsing effect
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Thêm giới hạn thời gian ghi âm (2 phút)
  static const int MAX_RECORDING_DURATION = 120; // 2 phút

  // Add a mounted check flag to prevent timer callbacks after dispose
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    print("AudioRecorderWidget initializing");

    // Initialize the recorder
    _audioRecorder = AudioRecorder();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Create the pulse animation
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Make sure we're visible first before requesting permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _initializeRecorder();
      }
    });

    // Remove the duplicate timer initialization - this will be handled in _startRecording
  }

  @override
  Future<void> dispose() async {
    print("🎤 Disposing AudioRecorderWidget");
    _isDisposed = true; // Mark as disposed first

    // Cancel any timers
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    // Stop recording if needed
    if (_isRecording) {
      try {
        await _stopRecording(canceled: true);
      } catch (e) {
        print("🎤 Error while stopping recording during dispose: $e");
      }
    }

    // Release resources
    try {
      await _audioRecorder.dispose();
    } catch (e) {
      print("🎤 Error while disposing audio recorder: $e");
    }

    // Dispose animation controller
    _animationController.dispose();

    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    try {
      print("🎤 Requesting microphone permission");
      // Request microphone permission
      final status = await Permission.microphone.request();
      print("🎤 Permission status: $status");

      if (status.isGranted) {
        print("🎤 Microphone permission granted - starting recording");
        setState(() => _isInitialized = true);
        await _startRecording(); // Wait for recording to start
        print("🎤 Recording started successfully");
      } else {
        print("🎤 Microphone permission denied with status: $status");
        // Show a snackbar to inform the user before canceling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Microphone permission required for recording')),
        );
        // Delay cancellation to allow user to see the message
        Future.delayed(Duration(seconds: 2), () {
          widget.onCancel();
        });
      }
    } catch (e) {
      print("🎤 ERROR initializing recorder: $e");
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start recording: $e')),
      );
      // Delay cancellation
      Future.delayed(Duration(seconds: 2), () {
        widget.onCancel();
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _isDisposed) {
      print("🎤 Recorder not initialized or widget disposed");
      return;
    }

    try {
      // Check if we have permission
      if (await _audioRecorder.hasPermission()) {
        print("🎤 Recorder has permission, setting up storage");

        // Create a more unique filename using timestamp
        String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        if (kIsWeb) {
          // On web, we don't specify the path - let the plugin handle it
          _recordingPath = fileName;
          print(
              "🎤 Web platform detected, using simple filename: $_recordingPath");
        } else {
          try {
            // Create a permanent audio directory in app documents
            final appDir = await getApplicationDocumentsDirectory();

            // Create an "audio_messages" directory instead of just "audio"
            final audioDir = Directory('${appDir.path}/audio_messages');
            if (!await audioDir.exists()) {
              await audioDir.create(recursive: true);
            }

            _recordingPath = '${audioDir.path}/$fileName';
            print("🎤 Using audio directory: ${audioDir.path}");
            print("🎤 Full recording path: $_recordingPath");
          } catch (e) {
            print("🎤 ERROR setting up directory: $e");
            // Fallback to just the filename and let the plugin decide
            _recordingPath = fileName;
            print("🎤 Using fallback path: $_recordingPath");
          }
        }

        // Ensure _recordingPath is not null
        final String recordingPath = _recordingPath ?? fileName;

        // Configure audio settings using RecordConfig for version 6.0.0
        final config = RecordConfig(
          encoder: AudioEncoder.aacLc, // AAC is widely supported
          bitRate: 160000, // Increased bitrate for better quality
          sampleRate: 44100,
        );

        // Start recording with the new API using non-nullable path
        await _audioRecorder.start(config, path: recordingPath);

        print("🎤 Recording started successfully");

        if (!_isDisposed) {
          setState(() {
            _isRecording = true;
            _recordDuration = 0;
          });
        }

        // Start timer to track recording duration with mounted check
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!_isDisposed && mounted) {
            setState(() {
              _recordDuration++;

              // Auto-stop recording if it exceeds the maximum duration
              if (_recordDuration >= MAX_RECORDING_DURATION) {
                print("🎤 Auto-stopping recording after reaching max duration");
                _stopRecording();
              }
            });
          } else {
            // Cancel timer if widget is disposed
            _timer?.cancel();
            _timer = null;
          }
        });
      } else {
        print("🎤 Recording permission not granted even after request");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission is required')),
        );
        Future.delayed(Duration(seconds: 1), () {
          widget.onCancel();
        });
      }
    } catch (e) {
      print("🎤 ERROR starting recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
      Future.delayed(Duration(seconds: 1), () {
        widget.onCancel();
      });
    }
  }

  Future<void> _stopRecording({bool canceled = false}) async {
    // Cancel timer first
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    if (!_isRecording) {
      print("🎤 Not recording, nothing to stop");
      return;
    }

    try {
      // Update UI state before async operation
      if (!_isDisposed && mounted) {
        setState(() => _isRecording = false);
      }

      print("🎤 Stopping recording...");

      // Đặt UI là đã dừng trước khi thực sự dừng ghi âm để tránh lag
      final path = await _audioRecorder.stop();
      print("🎤 Recording stopped, path: $path");

      if (canceled || path == null || _isDisposed) {
        print("🎤 Recording was canceled, path is null, or widget disposed");
        // Xóa file ghi âm nếu đã hủy
        if (path != null && !kIsWeb) {
          try {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
              print("🎤 Deleted canceled recording file");
            }
          } catch (e) {
            print("🎤 Error deleting file: $e");
          }
        }
        return;
      }

      // Xử lý file ghi âm
      if (!kIsWeb && path != null) {
        final audioFile = File(path);
        if (await audioFile.exists()) {
          final fileSize = await audioFile.length();
          print("🎤 Audio file saved. Size: ${fileSize} bytes");

          if (fileSize < 100) {
            print("🎤 WARNING: File size too small, empty recording");
            widget.onCancel();
            return;
          }

          // Chỉ kiểm tra xem file có đọc được không, không đọc toàn bộ file
          try {
            final randomAccessFile = await audioFile.open(mode: FileMode.read);
            await randomAccessFile.close();
            print("🎤 File accessible, calling onAudioSaved");
            widget.onAudioSaved(path);
          } catch (e) {
            print("🎤 ERROR: Could not access recorded file: $e");
            widget.onCancel();
          }
        } else {
          print("🎤 ERROR: File not found at path: $path");
          widget.onCancel();
        }
      } else if (kIsWeb && path != null) {
        // In this example, we assume the record package for web returns data already
        print("🎤 Web platform detected, using base64 approach");
        try {
          final bytes = await File(path!).readAsBytes();
          final base64Audio = base64Encode(bytes);
          widget.onAudioSaved(base64Audio);
        } catch (e) {
          print("🎤 Error processing web audio: $e");
          widget.onCancel();
        }
      }
    } catch (e) {
      print("🎤 ERROR stopping recording: $e");
      if (!_isDisposed) {
        widget.onCancel();
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    print("Building AudioRecorderWidget, isRecording: $_isRecording");

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title to make it more obvious
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Recording Audio",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),

          // Main recording controls row
          Row(
            children: [
              // Recording indicator with pulsing animation
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing effect using AnimatedBuilder
                  if (_isRecording)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 24 + (_pulseAnimation.value * 10),
                          height: 24 + (_pulseAnimation.value * 10),
                          decoration: BoxDecoration(
                            color: Colors.red
                                .withOpacity(0.3 * (1 - _pulseAnimation.value)),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  // Recording dot
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Recording duration
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              // Cancel button
              IconButton(
                onPressed: () {
                  _stopRecording(canceled: true);
                  widget.onCancel();
                },
                icon: Icon(Icons.close, color: Colors.red.shade700),
                tooltip: 'Cancel recording',
              ),

              // Stop and send button
              IconButton(
                onPressed: () => _stopRecording(),
                icon: const Icon(Icons.send, color: Colors.red),
                tooltip: 'Stop and send recording',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
