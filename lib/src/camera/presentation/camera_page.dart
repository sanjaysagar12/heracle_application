import 'dart:io';
import 'package:heracle/core/theme/app_colors.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  File? _previewFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  late AnimationController _fadeController;
  bool get isPreviewMode => _previewFile != null;
  CaptureMode _captureMode = CaptureMode.photo;
  bool _postSwitchRecord = false;

  String? _currentVideoPath;

  /// Helper to generate a path for the captured file
  Future<CaptureRequest> _path(List<Sensor> sensors, CaptureMode mode) async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir = await Directory(
      '${extDir.path}/camerawesome',
    ).create(recursive: true);
    final String fileExtension = mode == CaptureMode.photo ? 'jpg' : 'mp4';
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    if (mode == CaptureMode.video) {
      _currentVideoPath = filePath;
    }
    return SingleCaptureRequest(filePath, sensors.first);
  }

  Future<void> _pickGallery() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _previewFile = File(img.path));
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      _videoController = VideoPlayerController.file(_previewFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _startFadeOut();
        });
    }
  }

  void _startFadeOut() {
    _fadeController.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (_fadeController.isCompleted && mounted) {
        _fadeController.reverse();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// CAMERA VIEW
          if (!isPreviewMode)
            // ... inside your Stack
            CameraAwesomeBuilder.custom(
              saveConfig: SaveConfig.photoAndVideo(
                photoPathBuilder: (sensors) =>
                    _path(sensors, CaptureMode.photo),
                videoPathBuilder: (sensors) =>
                    _path(sensors, CaptureMode.video),
                initialCaptureMode: _captureMode,
              ),
              // FIX: Explicitly add types (CameraState, AnalysisPreview) here
              builder: (CameraState state, AnalysisPreview preview) {
                // Auto-record logic after switch
                if (_postSwitchRecord) {
                  state.when(
                    onVideoMode: (videoState) {
                      // Use post frame callback to avoid build conflicts
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _postSwitchRecord = false;
                          });
                          videoState.startRecording();
                        }
                      });
                    },
                    onPhotoMode: (p) {},
                    onVideoRecordingMode: (v) {},
                  );
                }

                return Stack(
                  children: [
                    /// CONTROLS
                    Positioned(
                      bottom: 35,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          /// PICK FROM GALLERY
                          GestureDetector(
                            onTap: _pickGallery,
                            child: const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.photo_library,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          /// CAPTURE BUTTON
                          AwesomeCaptureButton(
                            state: state,
                            onMediaCapture: (filePath) {
                              setState(() {
                                _previewFile = File(filePath);
                                _isVideo = filePath.endsWith('.mp4');
                              });
                            },
                            getCurrentVideoPath: () => _currentVideoPath,
                            onModeChange: (mode) {
                              setState(() => _captureMode = mode);
                            },
                            onSwitchToRecordingMode: () {
                              setState(() {
                                _postSwitchRecord = true;
                                _captureMode = CaptureMode.video;
                              });
                              // Trigger the switch
                              state.when(
                                onPhotoMode: (photoState) {
                                  photoState.setState(CaptureMode.video);
                                },
                                onVideoMode: (v) {},
                                onVideoRecordingMode: (v) {},
                              );
                            },
                          ),

                          /// SWITCH CAMERA
                          GestureDetector(
                            onTap: () {
                              state.switchCameraSensor();
                            },
                            child: const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.cameraswitch,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

          /// IMAGE / VIDEO PREVIEW
          if (isPreviewMode)
            _isVideo
                ? Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 100,
                    child: FutureBuilder<void>(
                      future: _initializeVideoPlayer(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return _videoController != null &&
                                  _videoController!.value.isInitialized
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _videoController!.value.isPlaying
                                          ? _videoController!.pause()
                                          : _videoController!.play();
                                    });
                                    _fadeController.forward();
                                    Future.delayed(
                                      const Duration(seconds: 3),
                                      () {
                                        if (_fadeController.isCompleted &&
                                            mounted) {
                                          _fadeController.reverse();
                                        }
                                      },
                                    );
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        color: Colors.black,
                                        child: Center(
                                          child: AspectRatio(
                                            aspectRatio: _videoController!
                                                .value
                                                .aspectRatio,
                                            child: AbsorbPointer(
                                              child: VideoPlayer(
                                                _videoController!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      FadeTransition(
                                        opacity: Tween<double>(
                                          begin: 1.0,
                                          end: 0.0,
                                        ).animate(_fadeController),
                                        child: Center(
                                          child: Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black54,
                                            ),
                                            child: Icon(
                                              _videoController!.value.isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                        }
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  )
                : Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 100,
                    child: Container(
                      color: Colors.black,
                      child: Image.file(_previewFile!, fit: BoxFit.contain),
                    ),
                  ),

          /// PREVIEW MODE CAPTION BAR (unchanged)
          if (isPreviewMode)
            Positioned(
              bottom: 20, // Moved up
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.black),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.black100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: const TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Add a caption…",
                              hintStyle: TextStyle(color: AppColors.white40),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Add your share logic here
                        },
                        icon: const Icon(Icons.telegram_sharp, size: 30), // Increased size
                        label: const Text(
                          "Share",
                          style: TextStyle(fontSize: 17),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          // Ensure minimum size matches if SizedBox wasn't enough (though SizedBox forces it)
                          minimumSize: const Size(0, 55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          /// RETAKE BUTTON (X Icon)
          if (isPreviewMode)
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _previewFile = null;
                    _videoController?.pause();
                    _videoController?.dispose();
                    _videoController = null;
                    _isVideo = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom Button to handle both Photo (Tap) and Video (Long Press) with Animation and Lock
class AwesomeCaptureButton extends StatefulWidget {
  final CameraState state;
  final Function(String) onMediaCapture;
  final String? Function() getCurrentVideoPath;
  final Function(CaptureMode) onModeChange;
  final VoidCallback? onSwitchToRecordingMode;

  const AwesomeCaptureButton({
    super.key,
    required this.state,
    required this.onMediaCapture,
    required this.getCurrentVideoPath,
    required this.onModeChange,
    this.onSwitchToRecordingMode,
  });

  @override
  State<AwesomeCaptureButton> createState() => _AwesomeCaptureButtonState();
}

class _AwesomeCaptureButtonState extends State<AwesomeCaptureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isRecording = false;
  bool _isLocked = false;
  final double _lockThreshold = -60.0; // Distance to drag up to lock

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AwesomeCaptureButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state with actual camera state
    if (widget.state is VideoRecordingCameraState) {
      if (!_isRecording) {
        setState(() {
          _isRecording = true;
        });
        _pulseController.forward();
      }
    } else if (widget.state is! VideoRecordingCameraState && _isRecording) {
      // Only reset if we are not in the middle of a switch-and-record flow
      // But actually, if state is NOT recording, we should probably stop UI recording unless we are waiting for the switch.
      // However, the parent handles the switch logic.
      // Let's rely on the parent's state.
      _resetUI();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _resetUI() {
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isLocked = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _startRecording() async {
    await widget.state.when(
      onPhotoMode: (photoState) async {
        // Delegate switch to parent
        widget.onSwitchToRecordingMode?.call();
      },
      onVideoMode: (videoState) async {
        setState(() {
          _isRecording = true;
          _isLocked = false;
        });
        _pulseController.forward();
        await videoState.startRecording();
      },
      onVideoRecordingMode: (videoRec) async {
        // Already recording
      },
    );
  }

  void _stopRecording() async {
    _resetUI();

    await widget.state.when(
      onVideoRecordingMode: (videoRec) async {
        await videoRec.stopRecording();
        final videoPath = widget.getCurrentVideoPath();
        if (videoPath != null) {
          widget.onMediaCapture(videoPath);
        }
      },
      onPhotoMode: (p) {},
      onVideoMode: (v) {},
    );
  }

  void _takePhoto() async {
    await widget.state.when(
      onPhotoMode: (photoState) async {
        final captureRequest = await photoState.takePhoto();
        captureRequest.when(
          single: (single) {
            if (single.file != null) {
              widget.onMediaCapture(single.file!.path);
            }
          },
          multiple: (multiple) {
            if (multiple.fileBySensor.isNotEmpty) {
              final firstFile = multiple.fileBySensor.values.first;
              if (firstFile != null) {
                widget.onMediaCapture(firstFile.path);
              }
            }
          },
        );
      },
      onVideoMode: (videoState) async {
        // Switch to photo? Or just ignore?
        // Usually tap in video mode might take a snapshot or do nothing.
        // For now, let's assume we want to take a photo, so switch mode.
        videoState.setState(CaptureMode.photo);
      },
      onVideoRecordingMode: (videoRec) async {
        // Maybe take a snapshot during recording?
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording && !_isLocked)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Icon(
              Icons.lock_open,
              color: Colors.white.withOpacity(0.8),
              size: 30,
            ),
          )
        else
          const SizedBox(height: 50), // Placeholder to keep layout stable

        GestureDetector(
          onTap: () {
            if (_isLocked) {
              _stopRecording();
            } else {
              _takePhoto();
            }
          },
          onLongPress: () {
            if (!_isLocked) {
              _startRecording();
            }
          },
          onLongPressMoveUpdate: (details) {
            if (_isRecording && !_isLocked) {
              // Check drag distance
              // localOffsetFromOrigin is relative to the touch start position
              if (details.localOffsetFromOrigin.dy < _lockThreshold) {
                setState(() {
                  _isLocked = true;
                });
              }
            }
          },
          onLongPressEnd: (details) {
            if (_isRecording) {
              if (_isLocked) {
                // Keep recording
              } else {
                _stopRecording();
              }
            }
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording && !_isLocked ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 73,
              height: 73,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.transparent,
                border: Border.all(width: 4, color: AppColors.pureWhite),
              ),
              child: _isLocked
                  ? const Icon(Icons.stop, color: Colors.white, size: 30)
                  : (_isRecording
                      ? const Icon(Icons.videocam, color: Colors.white)
                      : Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        )),
            ),
          ),
        ),
      ],
    );
  }
}
