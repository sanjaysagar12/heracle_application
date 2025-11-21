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
              bottom: 0,
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
                    ElevatedButton.icon(
                      onPressed: () {
                        // Add your share logic here
                      },
                      icon: const Icon(Icons.telegram_sharp),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom Button to handle both Photo (Tap) and Video (Long Press)
class AwesomeCaptureButton extends StatefulWidget {
  final CameraState state;
  final Function(String) onMediaCapture;
  final String? Function() getCurrentVideoPath;
  final Function(CaptureMode) onModeChange;

  const AwesomeCaptureButton({
    super.key,
    required this.state,
    required this.onMediaCapture,
    required this.getCurrentVideoPath,
    required this.onModeChange,
  });

  @override
  State<AwesomeCaptureButton> createState() => _AwesomeCaptureButtonState();
}

class _AwesomeCaptureButtonState extends State<AwesomeCaptureButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
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
            await videoState.startRecording();
          },
          onVideoRecordingMode: (videoRec) async {
            await videoRec.stopRecording();
            final videoPath = widget.getCurrentVideoPath();
            if (videoPath != null) {
              widget.onMediaCapture(videoPath);
            }
          },
        );
      },
      onLongPress: () async {
        await widget.state.when(
          onPhotoMode: (photoState) async {
            // Switch to video mode first
            photoState.setState(CaptureMode.video);
            // Wait for state transition
            await Future.delayed(const Duration(milliseconds: 200));
          },
          onVideoMode: (videoState) async {
            await videoState.startRecording();
          },
          onVideoRecordingMode: (videoRec) async {
            // Already recording
          },
        );
      },
      onLongPressUp: () async {
        await widget.state.when(
          onVideoRecordingMode: (videoRec) async {
            await videoRec.stopRecording();
            final videoPath = widget.getCurrentVideoPath();
            if (videoPath != null) {
              widget.onMediaCapture(videoPath);
            }
          },
        );
      },
      child: Container(
        width: 73,
        height: 73,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (widget.state is VideoRecordingCameraState)
              ? Colors.red
              : Colors.transparent,
          border: Border.all(width: 4, color: AppColors.pureWhite),
        ),
        child: (widget.state is VideoRecordingCameraState)
            ? const Icon(Icons.stop, color: Colors.white)
            : Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}
