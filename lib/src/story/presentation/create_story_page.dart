import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heracle/core/theme/app_colors.dart';
import 'package:heracle/src/story/domain/text_overlay.dart';
import 'package:heracle/src/story/presentation/text_editor_widget.dart';
import 'package:video_player/video_player.dart';

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
              // Update fields in-place so the existing overlay keeps its identity and transform
              overlay.text = updated.text;
              overlay.style = updated.style;
              overlay.color = updated.color;
              // Keep position/scale/rotation unless the editor returns different ones
              overlay.position = updated.position;
              overlay.scale = updated.scale;
              overlay.rotation = updated.rotation;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Media (InteractiveViewer)
          Positioned.fill(
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

          // Text Overlays Layer
          ..._textOverlays.map((overlay) {
            // Local start values captured per overlay instance for gestures
            double _startScale = overlay.scale;
            double _startRotation = overlay.rotation;

            return Positioned(
              left: overlay.position.dx,
              top: overlay.position.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // Open editor to edit this overlay
                  _openEditorForOverlay(overlay);
                },
                onScaleStart: (details) {
                  _startScale = overlay.scale;
                  _startRotation = overlay.rotation;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    // Scale: pinch to resize
                    overlay.scale = (_startScale * details.scale).clamp(0.3, 8.0);
                    // Rotation: two-finger rotate
                    overlay.rotation = _startRotation + details.rotation;
                    // Pan while scaling (or single finger pan)
                    // details.focalPointDelta is in global coordinates so we can move by it
                    overlay.position += details.focalPointDelta;
                  });
                },
                child: Transform.translate(
                  offset: Offset.zero,
                  child: Transform.scale(
                    scale: overlay.scale,
                    child: Transform.rotate(
                      angle: overlay.rotation,
                      child: Text(
                        overlay.text,
                        style: overlay.style,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

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
                  onTap: _addText,
                  child: _buildTopIcon(Icons.text_fields, "Text"),
                ),
                _buildTopIcon(Icons.face, "Stickers"),
                _buildTopIcon(Icons.music_note, "Music"),
                _buildTopIcon(Icons.auto_fix_high, "Effects"),
                _buildTopIcon(Icons.more_horiz, "More"),
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
