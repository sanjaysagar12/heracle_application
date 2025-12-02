import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heracle/core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Media
          Positioned.fill(
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
                _buildTopIcon(Icons.text_fields, "Text"),
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

  Widget _buildBottomPillButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor != null ? Colors.transparent : Colors.grey[700],
            ),
             child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
