import 'dart:io';
import 'package:heracle/main.dart'; // Added
import 'package:heracle/core/services/notification_service.dart';
import 'package:heracle/core/services/upload_manager.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:heracle/core/theme/app_colors.dart';
import 'package:heracle/src/camera/presentation/share_bottom_sheet.dart';
import 'package:heracle/src/camera/presentation/camera_nav_bar.dart';
import 'package:heracle/src/camera/domain/text_overlay.dart';
import 'package:heracle/src/camera/widgets/text_editor_widget.dart';
import 'package:heracle/src/story/data/story_repository.dart'; // Added
import 'package:camerawesome/camerawesome_plugin.dart' as cawesome;
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import 'package:heracle/src/nutrition/api/nutrition_service.dart';
import 'package:heracle/src/nutrition/data/diet_log_item.dart';
import 'package:heracle/src/nutrition/presentation/track_calories_page.dart'; // Added

enum _CameraMode { story, calAI }

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
  cawesome.CaptureMode _captureMode = cawesome.CaptureMode.photo;
  bool _postSwitchRecord = false;
  int _currentIndex = 1;
  _CameraMode _selectedMode = _CameraMode.calAI; // Default mode

  String? _currentVideoPath;

  // Text Overlay State
  final List<TextOverlay> _textOverlays = [];
  TextOverlay? _selectedOverlay;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;
  
  final GlobalKey _captureKey = GlobalKey(); // Added for capturing

  /// Helper to generate a path for the captured file
  Future<cawesome.CaptureRequest> _path(List<cawesome.Sensor> sensors, cawesome.CaptureMode mode) async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir = await Directory(
      '${extDir.path}/camerawesome',
    ).create(recursive: true);
    final String fileExtension = mode == cawesome.CaptureMode.photo ? 'jpg' : 'mp4';
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    if (mode == cawesome.CaptureMode.video) {
      _currentVideoPath = filePath;
    }
    return cawesome.SingleCaptureRequest(filePath, sensors.first);
  }

  Future<void> _pickGallery() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      if (_selectedMode == _CameraMode.calAI) {
        _handleCalAICapture(File(img.path));
      } else {
        setState(() => _previewFile = File(img.path));
      }
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
            if (overlay.text.isNotEmpty) {
              setState(() {
                _textOverlays.add(overlay);
              });
            }
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

  // Helper to capture RepaintBoundary to a temporary file
  Future<File> _capturePngToFile() async {
    final RenderRepaintBoundary boundary = _captureKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/story_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  Future<void> _shareStory(int index) async {
    // 1. Deselect overlay to avoid capturing selection border
    setState(() {
      _selectedOverlay = null;
    });
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      File fileToUpload;
      String mediaType;

      if (_isVideo && _previewFile != null) {
        fileToUpload = _previewFile!;
        mediaType = 'VIDEO';
      } else {
        fileToUpload = await _capturePngToFile();
        mediaType = 'IMAGE';
      }

      // Fake delay for "Processing" feeling (Optimistic UI)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Story shared successfully!"),
            backgroundColor: AppColors.primary,
          ),
        );

      // 3. Upload with UploadManager
        final uploadManager = UploadManager();
        final uploadId = uploadManager.startUpload(
          title: 'Posting Story',
          type: 'story',
        );

        // index 0: Public Story (isHighlighted = false)
        // index 1: Spotlight (isHighlighted = true)
        final bool isHighlighted = index == 1;
        final String caption = _captionController.text;

        // BACKGROUND: Actual Upload
        final repository = StoryRepository();
        repository.createStory(
          fileToUpload, 
          caption, 
          isHighlighted: isHighlighted,
          mediaType: mediaType,
          onProgress: (progress) {
            uploadManager.updateProgress(uploadId, progress);
          },
        ).then((_) {
            uploadManager.updateProgress(uploadId, 1.0);
            uploadManager.completeUpload(uploadId);

            NotificationService().showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: 'Story Shared',
                body: 'Your story has been created successfully!',
            );
            
            // In-App Success
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                content: Text('Your story is now live!'),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 3),
              ),
            );
        }).catchError((e) {
             debugPrint("Background upload failed: $e");
             uploadManager.failUpload(uploadId, errorMessage: 'Upload failed. Please try again.');
             
             NotificationService().showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: 'Story Failed',
                body: 'Failed to upload story. Please try again.',
            );
        });

        // Navigate to Home immediately
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to share story: $e")),
        );
      }
    }
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
                if (index == 1) return; // Stay on camera page
                Navigator.pop(context, index);
              },
            ),
      body: Stack(
        children: [
            /// CAMERA VIEW
          if (!isPreviewMode)
            // ...existing code...
            cawesome.CameraAwesomeBuilder.custom(
              saveConfig: cawesome.SaveConfig.photoAndVideo(
                photoPathBuilder: (sensors) =>
                    _path(sensors, cawesome.CaptureMode.photo),
                videoPathBuilder: (sensors) =>
                    _path(sensors, cawesome.CaptureMode.video),
                initialCaptureMode: _captureMode,
              ),
              sensorConfig: cawesome.SensorConfig.single(
                sensor: cawesome.Sensor.position(cawesome.SensorPosition.back),
                aspectRatio: cawesome.CameraAspectRatios.ratio_4_3,
              ),
              builder: (cawesome.CameraState state, cawesome.AnalysisPreview preview) {
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
                    /// MODES (Vertical Right Center)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildModeButton('Story', _selectedMode == _CameraMode.story),
                            const SizedBox(height: 30),
                            _buildModeButton('Cal AI', _selectedMode == _CameraMode.calAI),
                          ],
                        ),
                      ),
                    ),

                    /// CONTROLS
                    Positioned(
                      bottom: 35,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mode Selector Removed

                          Row(
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
                                  if (_selectedMode == _CameraMode.calAI) {
                                    _handleCalAICapture(File(filePath));
                                  } else {
                                    setState(() {
                                      _previewFile = File(filePath);
                                      _isVideo = filePath.endsWith('.mp4');
                                    });
                                  }
                                },
                                getCurrentVideoPath: () => _currentVideoPath,
                                onModeChange: (mode) {
                                  setState(() => _captureMode = mode);
                                },
                                onSwitchToRecordingMode: () {
                                  if (_selectedMode == _CameraMode.calAI) return; // Disable video for Cal AI
                                  setState(() {
                                    _postSwitchRecord = true;
                                    _captureMode = cawesome.CaptureMode.video;
                                  });
                                  // Trigger the switch
                                  state.when(
                                    onPhotoMode: (photoState) {
                                      photoState.setState(cawesome.CaptureMode.video);
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
                              onDownload: () {
                                Navigator.pop(context);
                                _saveStory();
                              },
                              onShare: (index) { // Added callback
                                _shareStory(index);
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

  Widget _buildModeButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = text == 'Story' ? _CameraMode.story : _CameraMode.calAI;
          if (_selectedMode == _CameraMode.calAI) {
            _captureMode = cawesome.CaptureMode.photo; // Force photo mode for Cal AI
          }
        });
      },
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        style: TextStyle(
          fontFamily: 'Roboto', // Explicitly set font family to avoid jumping if it changes
          color: isSelected ? AppColors.pureWhite : AppColors.white40,
          fontSize: isSelected ? 24 : 16,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(1, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(text),
      ),
    );
  }

  Future<void> _handleCalAICapture(File imageFile) async {
      if (!mounted) return;

      // Navigate directly to Track Calories Page with the captured image
      // The analysis and description prompt will handle there.
      final item = DietLogItem(
        imagePath: imageFile.path,
        isLoading: true, // Mark as loading so TrackCaloriesPage knows to initiate flow
      );

      final result = await Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => const TrackCaloriesPage(),
          settings: RouteSettings(arguments: item),
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
  }
}

/// Custom Button to handle both Photo (Tap) and Video (Long Press) with Animation and Lock
class AwesomeCaptureButton extends StatefulWidget {
  final cawesome.CameraState state;
  final Function(String) onMediaCapture;
  final String? Function() getCurrentVideoPath;
  final Function(cawesome.CaptureMode) onModeChange;
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
    if (widget.state is cawesome.VideoRecordingCameraState) {
      if (!_isRecording) {
        setState(() {
          _isRecording = true;
        });
        _pulseController.forward();
      }
    } else if (widget.state is! cawesome.VideoRecordingCameraState && _isRecording) {
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
        videoState.setState(cawesome.CaptureMode.photo);
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
                        color: Colors.white.withOpacity(0.5),
                        width: 2 / overlay.scale),
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
