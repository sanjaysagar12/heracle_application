import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart'; // Added dependency
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:heracle/core/theme/app_colors.dart';
import 'package:heracle/src/story/domain/text_overlay.dart';
import 'package:heracle/src/story/presentation/text_editor_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class CreateStoryPage extends StatefulWidget {
  final String filePath;
  final String? caption;

  const CreateStoryPage({
    super.key,
    required this.filePath,
    this.caption,
  });

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  late bool _isVideo;
  VideoPlayerController? _videoController;
  late TextEditingController _captionController;
  final List<TextOverlay> _textOverlays = [];
  TextOverlay? _selectedOverlay;
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.caption);
    _isVideo = widget.filePath.endsWith('.mp4');
    if (_isVideo) {
      _videoController = VideoPlayerController.file(File(widget.filePath))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
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

  // New: open editor for an existing overlay and update it in-place
  void _openEditorForOverlay(TextOverlay overlay) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => TextEditorWidget(
          initialOverlay: overlay,
          onDone: (updated) {
            setState(() {
              // If text is empty after editing, remove the overlay
              if (updated.text.isEmpty) {
                _textOverlays.remove(overlay);
                _selectedOverlay = null;
              } else {
                // Update fields in-place
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("Save to Gallery"),
              onTap: () {
                Navigator.pop(context);
                _saveStory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text("Cancel"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStory() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        // On Android 13+ (SDK 33), use photos permission (READ_MEDIA_IMAGES)
        if (androidInfo.version.sdkInt >= 33) {
          status = await Permission.photos.request();
        } else {
          // On older Android, use storage permission
          status = await Permission.storage.request();
        }
      } catch (e) {
        // Fallback if DeviceInfoPlugin fails (e.g. MissingPluginException before rebuild)
        debugPrint("DeviceInfoPlugin failed: $e. App needs full restart. Trying fallback permissions.");
        
        // Try storage first
        status = await Permission.storage.request();
        
        // If storage is denied (likely Android 13+ where it's invalid), try photos
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }
    } else {
      // iOS
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      return;
    }

    // Deselect any selected overlay before capturing
    setState(() {
      _selectedOverlay = null;
    });

    // Wait for UI to update
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (_isVideo) {
        await _saveVideoWithOverlays();
      } else {
        await _saveImageWithOverlays();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    }
  }

  Future<void> _saveImageWithOverlays() async {
    try {
      // Show loading
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

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: "story_${DateTime.now().millisecondsSinceEpoch}",
      );

      Navigator.pop(context); // Dismiss loading

      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image saved to gallery!")),
        );
      } else {
        throw Exception("Failed to save image");
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      rethrow;
    }
  }

  Future<void> _saveVideoWithOverlays() async {
    // For video, we'll save a thumbnail with overlays for now
    // Full video editing with overlays requires FFmpeg integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Video saving with overlays coming soon!\nSaving thumbnail for now..."),
      ),
    );

    // Pause video and capture current frame
    await _videoController?.pause();
    await _saveImageWithOverlays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Wrap the entire story view in RepaintBoundary for capturing
          RepaintBoundary(
            key: _captureKey,
            child: Stack(
              children: [
                // Background Media
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (_selectedOverlay != null) {
                        setState(() {
                          _selectedOverlay = null;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      absorbing: _selectedOverlay != null,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        child: _isVideo
                            ? (_videoController != null && _videoController!.value.isInitialized
                                ? Center(
                                    child: AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                  )
                                : const Center(child: CircularProgressIndicator()))
                            : Image.file(
                                File(widget.filePath),
                                fit: BoxFit.contain,
                              ),
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
                      onUpdate: () {
                        setState(() {});
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Delete button for selected overlay
          if (_selectedOverlay != null)
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

          // Top Bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOverlay = null;
                    });
                    _addText();
                  },
                  child: _buildTopIcon(Icons.text_fields, "Text"),
                ),
                _buildTopIcon(Icons.face, "Stickers"),
                _buildTopIcon(Icons.music_note, "Music"),
                _buildTopIcon(Icons.auto_fix_high, "Effects"),
                GestureDetector(
                  onTap: _showMoreOptions,
                  child: _buildTopIcon(Icons.more_horiz, "More"),
                ),
              ],
            ),
          ),

          // Bottom Area: Caption Input + Forward Button
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Add a caption...",
                        hintStyle: TextStyle(
                          color: Colors.white70,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      maxLines: null,
                      minLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    // Handle post action
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

/// Separate widget to handle individual text overlay gestures
class _TextOverlayWidget extends StatefulWidget {
  final TextOverlay overlay;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onUpdate;

  const _TextOverlayWidget({
    required this.overlay,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onUpdate,
  });

  @override
  State<_TextOverlayWidget> createState() => _TextOverlayWidgetState();
}

class _TextOverlayWidgetState extends State<_TextOverlayWidget> {
  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _startPosition = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _startLocalFocalPoint = Offset.zero;
  int _pointerCount = 0;
  final GlobalKey _textKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _pointerCount++,
      onPointerUp: (_) => _pointerCount--,
      onPointerCancel: (_) => _pointerCount--,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onScaleStart: (details) {
          widget.onTap();
          _startScale = widget.overlay.scale;
          _startRotation = widget.overlay.rotation;
          _startPosition = widget.overlay.position;
          _startFocalPoint = details.focalPoint;
          _startLocalFocalPoint = details.localFocalPoint;
        },
        onScaleUpdate: (details) {
          if (!widget.isSelected) return;

          if (_pointerCount == 1) {
            // Single finger: only move (pan)
            final delta = details.focalPoint - _startFocalPoint;
            widget.overlay.position = _startPosition + delta;
          } else if (_pointerCount >= 2) {
            // Two fingers: scale and rotate
            
            // Apply scale
            final newScale = (_startScale * details.scale).clamp(0.3, 8.0);
            widget.overlay.scale = newScale;
            
            // Apply rotation
            final deltaRotation = details.rotation;
            widget.overlay.rotation = _startRotation + deltaRotation;
            
            // Calculate position adjustment to keep the pinch point fixed
            // The local focal point (relative to widget) should stay under fingers
            
            // Start: where the focal point was relative to widget start position
            final startFocalInWidget = _startLocalFocalPoint;
            
            // Apply scale to that point
            final scaledFocal = Offset(
              startFocalInWidget.dx * (newScale / _startScale),
              startFocalInWidget.dy * (newScale / _startScale),
            );
            
            // Apply rotation to that scaled point
            final rotatedScaledFocal = _rotateOffset(scaledFocal, deltaRotation);
            
            // New position: current focal point minus the transformed local focal point
            widget.overlay.position = details.focalPoint - rotatedScaledFocal;
          }

          widget.onUpdate();
        },
        child: Transform.scale(
          scale: widget.overlay.scale,
          alignment: Alignment.topLeft,
          child: Transform.rotate(
            angle: widget.overlay.rotation,
            alignment: Alignment.topLeft,
            child: Container(
              key: _textKey,
              padding: const EdgeInsets.all(8),
              decoration: widget.isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                widget.overlay.text,
                style: widget.overlay.style,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _rotateOffset(Offset offset, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(
      offset.dx * cos - offset.dy * sin,
      offset.dx * sin + offset.dy * cos,
    );
  }
}
