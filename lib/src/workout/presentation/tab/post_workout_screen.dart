import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import '../../../../core/theme/app_colors.dart';
import '../../data/post_workout_repository.dart';

class PostWorkoutScreen extends StatefulWidget {
  final int duration; // in seconds
  final int volume;
  final List<Map<String, dynamic>> exercises;
  
  // Edit mode parameters
  final String? postId;
  final String? initialCaption;
  final List<String>? initialTags;

  const PostWorkoutScreen({
    super.key,
    required this.duration,
    required this.volume,
    required this.exercises,
    this.postId,
    this.initialCaption,
    this.initialTags,
  });

  @override
  State<PostWorkoutScreen> createState() => _PostWorkoutScreenState();
}

class _PostWorkoutScreenState extends State<PostWorkoutScreen> {
  final TextEditingController _captionController = TextEditingController();
  final PostWorkoutRepository _repository = PostWorkoutRepository();
  List<File> _selectedImages = [];
  final List<String> _tags = []; // Store extracted tags
  bool _isPosting = false;
  bool _isPublic = true;
  bool get _isEditMode => widget.postId != null;

  int get _totalSets {
    int count = 0;
    for (var ex in widget.exercises) {
      final sets = ex['sets'] as List<dynamic>?;
      if (sets != null) {
        count += sets.length;
      }
    }
    return count;
  }

  String get _formattedDuration {
    final minutes = (widget.duration / 60).floor();
    final seconds = widget.duration % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _captionController.text = widget.initialCaption ?? '';
      if (widget.initialTags != null) {
        _tags.addAll(widget.initialTags!);
      }
    }
    _captionController.addListener(_onCaptionChanged);
  }

  @override
  void dispose() {
    _captionController.removeListener(_onCaptionChanged);
    _captionController.dispose();
    super.dispose();
  }

  void _onCaptionChanged() {
    String text = _captionController.text;
    
    // Check if the last character typed is a space
    if (text.isNotEmpty && text.endsWith(' ')) {
      // Find the last word
      List<String> words = text.trimRight().split(' ');
      if (words.isNotEmpty) {
        String lastWord = words.last;
        if (lastWord.startsWith('#') && lastWord.length > 1) {
          String tag = lastWord.substring(1); // remove #
          
          // Add to tags if not duplicate (optional, but good UX)
          if (!_tags.contains(tag)) {
            setState(() {
              _tags.add(tag);
            });
          }

          // Remove the hashtag from the text
          // We need to be careful to remove only the last occurrence or the specific one typed
          // Since we just typed it, it should be at the end (ignoring the trailing space we just detected)
          // The current text is "... #tag "
          final newText = text.substring(0, text.length - (lastWord.length + 1));
          
          // Update controller without triggering loop (limitations apply, but set value works)
          _captionController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.fromPosition(TextPosition(offset: newText.length)),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isEditMode) return; // Disable image picking in edit mode
    final picker = img_picker.ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  void _addHashtagSymbol() {
    final text = _captionController.text;
    final newText = text.endsWith(' ') || text.isEmpty ? '$text#' : '$text #';
    _captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.fromPosition(TextPosition(offset: newText.length)),
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _postWorkout() async {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      if (_isEditMode) {
         await _repository.updatePost(
           widget.postId!,
           caption: _captionController.text,
           tags: _tags,
         );
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout updated successfully!')),
          );
          Navigator.pop(context, true); // Return true to signal update
        }
      } else {
        await _repository.postWorkout(
          caption: _captionController.text,
          isPublic: _isPublic,
          tags: _tags,
          duration: widget.duration,
          volume: widget.volume,
          exercises: widget.exercises,
          imagePaths: _selectedImages.map((e) => e.path).toList(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout posted successfully!')),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
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
        title: Text(_isEditMode ? 'Edit Workout' : 'Post Workout', style: const TextStyle(color: AppColors.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section: Photos & Caption
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Picker Card
                      if (!_isEditMode) ...[ // Only show in create mode or show simplified in edit
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 140, // increased height to match container
                            decoration: BoxDecoration(
                              color: AppColors.black100,
                              borderRadius: BorderRadius.circular(16),
                              image: _selectedImages.isNotEmpty
                                  ? DecorationImage(
                                      image: FileImage(_selectedImages.first),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _selectedImages.isEmpty
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, color: AppColors.pureWhite, size: 30),
                                      SizedBox(height: 4),
                                      Text('Add Photos',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: AppColors.white60, fontSize: 12)),
                                    ],
                                  )
                                : _selectedImages.length > 1
                                    ? Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          margin: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                              color: Colors.black54, shape: BoxShape.circle),
                                          child: Text('+${_selectedImages.length - 1}',
                                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      // Caption Input with Tags
                      Expanded(
                        child: Container(
                          height: 140, // Increased height to accommodate tags
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.black.withOpacity(0.5), 
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _captionController,
                                  maxLines: null,
                                  expands: true,
                                  style: const TextStyle(color: AppColors.pureWhite, fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'Write a caption...',
                                    hintStyle: TextStyle(color: AppColors.white60),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Chips Row
                              SizedBox(
                                height: 32,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    // # Hashtags Button
                                    GestureDetector(
                                      onTap: _addHashtagSymbol,
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCCFF00), // Lime green
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Center(
                                          child: Text('# Hashtags', 
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ),
                                    ),
                                    // Extracted Tags
                                    ..._tags.map((tag) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2C2C2E), // Darker grey like image
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _removeTag(tag),
                                            child: const Icon(Icons.close, size: 16, color: Color(0xFFCCFF00)), // Lime X
                                          ),
                                          const SizedBox(width: 6),
                                          Text(tag, style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 13, fontWeight: FontWeight.w500)), // Lime text
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Workout Log Section
                  const Text('Workout log', style: TextStyle(color: AppColors.white60, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(_formattedDuration, 'Duration'),
                      _buildStatCard('${widget.volume}kg', 'Volume'),
                      _buildStatCard('$_totalSets', 'Set Count'),
                      _buildStatCard('${widget.exercises.length.toString().padLeft(2, '0')}', 'Workouts'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Exercises List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.exercises.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final ex = widget.exercises[index];
                      return _buildExerciseCard(ex);
                    },
                  ),

                   // "See X more exercises" placeholder logic if we were paginating, 
                   // but here we show all. Maybe add a spacer or bottom padding.
                   const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Bottom Post Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.black,
              border: Border(top: BorderSide(color: AppColors.black100)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isPosting ? null : _postWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00), // Lime green as per design
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        _isEditMode ? 'Update Workout' : 'Post Workout',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 75,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(color: AppColors.pureWhite, fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.white60, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ex) {
    final sets = (ex['sets'] as List<dynamic>?) ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.greyDark,
                backgroundImage: ex['image'] != null ? NetworkImage(ex['image']) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex['name'] ?? 'Exercise',
                      style: const TextStyle(color: AppColors.pureWhite, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ex['desc'] ?? 'Muscle', // Using desc as subtitle/bodypart placehoder
                      style: const TextStyle(color: AppColors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sets
          if (sets.isNotEmpty)
            ...sets.asMap().entries.map((entry) {
              final i = entry.key;
              final set = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Set ${i + 1}',
                        style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Weight', style: TextStyle(color: AppColors.white60, fontSize: 14)),
                          const SizedBox(width: 8),
                          _buildValueBadge('${set['kg'] ?? 0}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Reps', style: TextStyle(color: AppColors.white60, fontSize: 14)),
                          const SizedBox(width: 8),
                          _buildValueBadge('${set['reps'] ?? 0}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
        ],
      ),
    );
  }

  Widget _buildValueBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greyDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.pureWhite, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
