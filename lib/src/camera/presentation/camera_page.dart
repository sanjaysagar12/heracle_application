import 'dart:io';
import 'dart:typed_data'; // Added
import 'dart:ui' as ui; // Added
import 'package:device_info_plus/device_info_plus.dart'; // Added
import 'package:flutter/rendering.dart'; // Added
import 'package:heracle/core/theme/app_colors.dart';
import 'package:heracle/src/camera/presentation/share_bottom_sheet.dart';
import 'package:heracle/src/camera/presentation/camera_nav_bar.dart';
import 'package:heracle/src/camera/domain/text_overlay.dart';
import 'package:heracle/src/camera/widgets/text_editor_widget.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; // Added
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Added
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
  int _currentIndex = 1;

  String? _currentVideoPath;

  // Text Overlay State
  final List<TextOverlay> _textOverlays = [];
  TextOverlay? _selectedOverlay;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;
  
  final GlobalKey _captureKey = GlobalKey(); // Added for capturing

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

  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _fadeController.dispose();
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _addText() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => TextEditorWidget(
          onDone: (overlay) {
            setState(() {
              _textOverlays.add(overlay);
            });
          },
        ),
      ),
    );
  }

  void _openEditorForOverlay(TextOverlay overlay) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => TextEditorWidget(
          initialOverlay: overlay,
          onDone: (updated) {
            setState(() {
              if (updated.text.isEmpty) {
                _textOverlays.remove(overlay);
                _selectedOverlay = null;
              } else {
                overlay.text = updated.text;
                overlay.style = updated.style;
                overlay.color = updated.color;
                overlay.position = updated.position;
                overlay.scale = updated.scale;
                overlay.rotation = updated.rotation;
              }
            });
          },
        ),
      ),
    );
  }

  // Added: Save Story Logic
  Future<void> _saveStory() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      } catch (e) {
        debugPrint("DeviceInfoPlugin failed: $e. Trying fallback.");
        status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
      }
      return;
    }

    setState(() {
      _selectedOverlay = null;
    });
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (_isVideo) {
        await _saveVideoWithOverlays();
      } else {
        await _saveImageWithOverlays();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e")),
        );
      }
    }
  }

  Future<void> _saveImageWithOverlays() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final RenderRepaintBoundary boundary = _captureKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: "story_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (mounted) Navigator.pop(context); // Dismiss loading

      if (result['isSuccess']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image saved to gallery!")),
          );
        }
      } else {
        throw Exception("Failed to save image");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      rethrow;
    }
  }

  Future<void> _saveVideoWithOverlays() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video saving with overlays coming soon!\nSaving thumbnail for now..."),
        ),
      );
    }
    await _videoController?.pause();
    await _saveImageWithOverlays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: isPreviewMode
          ? null
          : CameraNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
      body: Stack(
        children: [
          /// CAMERA VIEW
          if (!isPreviewMode)
            // ...existing code...
            CameraAwesomeBuilder.custom(
              saveConfig: SaveConfig.photoAndVideo(
                photoPathBuilder: (sensors) =>
                    _path(sensors, CaptureMode.photo),
                videoPathBuilder: (sensors) =>
                    _path(sensors, CaptureMode.video),
                initialCaptureMode: _captureMode,
              ),
              sensorConfig: SensorConfig.single(
                sensor: Sensor.position(SensorPosition.back),
                aspectRatio: CameraAspectRatios.ratio_4_3,
              ),
              builder: (CameraState state, AnalysisPreview preview) {
                // ...existing code...
                if (_postSwitchRecord) {
                  state.when(
                    onVideoMode: (videoState) {
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

          /// IMAGE / VIDEO PREVIEW WITH OVERLAYS
          if (isPreviewMode)
            Positioned.fill(
              child: RepaintBoundary( // Added RepaintBoundary
                key: _captureKey,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onScaleStart: _selectedOverlay != null
                      ? (details) {
                          _baseScale = _selectedOverlay!.scale;
                          _baseRotation = _selectedOverlay!.rotation;
                          _basePosition = _selectedOverlay!.position;
                        }
                      : null,
                  onScaleUpdate: _selectedOverlay != null
                      ? (details) {
                          setState(() {
                            _selectedOverlay!.scale =
                                (_baseScale * details.scale).clamp(0.3, 8.0);
                            _selectedOverlay!.rotation =
                                _baseRotation + details.rotation;
                            _selectedOverlay!.position += details.focalPointDelta;
                          });
                        }
                      : null,
                  onTap: () {
                    if (_selectedOverlay != null) {
                      setState(() {
                        _selectedOverlay = null;
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      // Media Layer
                      Positioned.fill(
                        child: AbsorbPointer(
                          absorbing: _selectedOverlay != null,
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            child: _isVideo
                                ? FutureBuilder<void>(
                                    future: _initializeVideoPlayer(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        return _videoController != null &&
                                                _videoController!
                                                    .value.isInitialized
                                            ? GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _videoController!
                                                            .value.isPlaying
                                                        ? _videoController!
                                                            .pause()
                                                        : _videoController!
                                                            .play();
                                                  });
                                                  _fadeController.forward();
                                                  Future.delayed(
                                                    const Duration(seconds: 3),
                                                    () {
                                                      if (_fadeController
                                                              .isCompleted &&
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
                                                          aspectRatio:
                                                              _videoController!
                                                                  .value
                                                                  .aspectRatio,
                                                          child: VideoPlayer(
                                                            _videoController!,
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
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Colors.black54,
                                                          ),
                                                          child: Icon(
                                                            _videoController!
                                                                    .value
                                                                    .isPlaying
                                                                ? Icons.pause
                                                                : Icons
                                                                    .play_arrow,
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
                                                  child:
                                                      CircularProgressIndicator(),
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
                                  )
                                : Container(
                                    color: Colors.black,
                                    child: Image.file(_previewFile!,
                                        fit: BoxFit.contain),
                                  ),
                          ),
                        ),
                      ),

                      // Text Overlays Layer
                      ..._textOverlays.map((overlay) {
                        final isSelected = _selectedOverlay == overlay;
                        return Positioned(
                          left: overlay.position.dx,
                          top: overlay.position.dy,
                          child: _TextOverlayWidget(
                            overlay: overlay,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedOverlay = overlay;
                              });
                            },
                            onDoubleTap: () {
                              _openEditorForOverlay(overlay);
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),

          // Delete button for selected overlay
          if (isPreviewMode && _selectedOverlay != null)
            Positioned(
              left: _selectedOverlay!.position.dx - 30,
              top: _selectedOverlay!.position.dy - 30,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _textOverlays.remove(_selectedOverlay);
                    _selectedOverlay = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),

          /// PREVIEW MODE CAPTION BAR
          if (isPreviewMode)
            Positioned(
              bottom: 20,
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
                          child: TextField(
                            controller: _captionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
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
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ShareBottomSheet(
                              filePath: _previewFile!.path,
                              caption: _captionController.text,
                              onDownload: () { // Added callback
                                Navigator.pop(context);
                                _saveStory();
                              },
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.telegram_sharp,
                          size: 30,
                        ),
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
                          minimumSize: const Size(0, 55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          /// ADD TEXT BUTTON
          if (isPreviewMode)
            Positioned(
              top: 40,
              right: 70,
              child: GestureDetector(
                onTap: _addText,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.text_fields,
                      color: Colors.white, size: 30),
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
                    _textOverlays.clear(); // Clear overlays
                    _selectedOverlay = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 30),
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
/// Separate widget to handle individual text overlay gestures
class _TextOverlayWidget extends StatelessWidget {
  final TextOverlay overlay;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _TextOverlayWidget({
    required this.overlay,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Transform.scale(
        scale: overlay.scale,
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: overlay.rotation,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              overlay.text,
              style: overlay.style,
            ),
          ),
        ),
      ),
    );
  }
}
