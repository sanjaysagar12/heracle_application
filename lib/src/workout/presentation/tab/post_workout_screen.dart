import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import '../../../../core/theme/app_colors.dart';
import '../../data/post_workout_repository.dart';

class PostWorkoutScreen extends StatefulWidget {
  final int duration;
  final int volume;
  final List<Map<String, dynamic>> exercises;

  const PostWorkoutScreen({
    super.key,
    required this.duration,
    required this.volume,
    required this.exercises,
  });

  @override
  State<PostWorkoutScreen> createState() => _PostWorkoutScreenState();
}

class _PostWorkoutScreenState extends State<PostWorkoutScreen> {
  final TextEditingController _captionController = TextEditingController();
  final PostWorkoutRepository _repository = PostWorkoutRepository();
  File? _selectedImage;
  bool _isPosting = false;
  bool _isPublic = true;

  Future<void> _pickImage() async {
    final picker = img_picker.ImagePicker();
    final pickedFile = await picker.pickImage(source: img_picker.ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  List<String> _extractTags(String text) {
    final regex = RegExp(r'\#\w+');
    return regex.allMatches(text).map((m) => m.group(0)!.substring(1)).toList();
  }

  Future<void> _postWorkout() async {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final tags = _extractTags(_captionController.text);
      await _repository.postWorkout(
        caption: _captionController.text,
        isPublic: _isPublic,
        tags: tags,
        duration: widget.duration,
        volume: widget.volume,
        exercises: widget.exercises,
        imagePath: _selectedImage?.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout posted successfully!')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post workout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post Workout', style: TextStyle(color: AppColors.pureWhite)),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _postWorkout,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.black100,
                  borderRadius: BorderRadius.circular(16),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: AppColors.white60, size: 40),
                          SizedBox(height: 8),
                          Text('Add Photo', style: TextStyle(color: AppColors.white60)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            // Caption Input
            const Text('Caption', style: TextStyle(color: AppColors.pureWhite, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.pureWhite),
              decoration: InputDecoration(
                hintText: 'Write a caption... Use #hashtags',
                hintStyle: const TextStyle(color: AppColors.white60),
                filled: true,
                fillColor: AppColors.black100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (text) {
                 // Simple way to trigger rebuild for highlighting if we were using a rich text editor
                 // For now, standard TextField doesn't support easy rich text editing with dynamic highlighting
                 // without a custom controller.
                 // We will implement a basic version where we just detect tags for logic.
                 // If advanced highlighting is needed, we'd need a custom TextEditingController.
              },
            ),
             const SizedBox(height: 24),
             // Public Toggle
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Public Post', style: TextStyle(color: AppColors.pureWhite, fontSize: 16)),
                 Switch(
                   value: _isPublic,
                   onChanged: (val) => setState(() => _isPublic = val),
                   activeColor: AppColors.primary,
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }
}
