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

  // State for gesture handling at page level
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;

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
            child: GestureDetector(
              // This detector handles gestures for the selected overlay anywhere on screen
              onScaleStart: (details) {
                if (_selectedOverlay == null) return;
                _baseScale = _selectedOverlay!.scale;
                _baseRotation = _selectedOverlay!.rotation;
                _basePosition = _selectedOverlay!.position;
              },
              onScaleUpdate: (details) {
                if (_selectedOverlay == null) return;
                setState(() {
                  // Scale
                  _selectedOverlay!.scale = (_baseScale * details.scale).clamp(0.3, 8.0);
                  
                  // Rotation
                  _selectedOverlay!.rotation = _baseRotation + details.rotation;
                  
                  // Position (Pan)
                  // We rotate the focal point delta to match the rotation if needed, 
                  // but usually for "drag anywhere" simple addition is intuitive enough 
                  // or we just add the delta.
                  // details.focalPointDelta is the movement since last update.
                  _selectedOverlay!.position += details.focalPointDelta;
                });
              },
              onTap: () {
                // Deselect if tapping empty space
                if (_selectedOverlay != null) {
                  setState(() {
                    _selectedOverlay = null;
                  });
                }
              },
              child: Stack(
                children: [
                  // Background Media
                  Positioned.fill(
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
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
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
