import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../nutrition/data/diet_log_item.dart';
import '../../nutrition/api/nutrition_service.dart';

class PostNutritionPage extends StatefulWidget {
  final List<DietLogItem> items;
  final int totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final String mealType;

  const PostNutritionPage({
    super.key,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.mealType,
  });

  @override
  State<PostNutritionPage> createState() => _PostNutritionPageState();
}

class _PostNutritionPageState extends State<PostNutritionPage> {
  final TextEditingController _captionController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Post Diet', style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pureWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Image Upload & Caption
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add Photos Button
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            height: 130,
                            decoration: BoxDecoration(
                              color: AppColors.black100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.white10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.greyDark.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.add, color: AppColors.pureWhite),
                                ),
                                const SizedBox(height: 8),
                                const Text('Add Photos', style: TextStyle(color: AppColors.pureWhite, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Caption
                        Expanded(
                          child: Container(
                            height: 130,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.black100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _captionController,
                                    maxLines: null,
                                    style: const TextStyle(color: AppColors.pureWhite),
                                    decoration: const InputDecoration(
                                      hintText: 'Write a caption with hashtags...',
                                      hintStyle: TextStyle(color: AppColors.white40, fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                // Tag placeholders
                                SingleChildScrollView(
                                   scrollDirection: Axis.horizontal,
                                   child: Row(
                                     children: [
                                       _buildTag('# Hashtags', AppColors.primary, AppColors.black),
                                       const SizedBox(width: 8),
                                       _buildTag('Back day', AppColors.greyDark, AppColors.white60),
                                     ],
                                   ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Selected Images Preview
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(File(_selectedImages[index].path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // "Diet log" Header
                    const Text(
                      'Diet log',
                      style: TextStyle(color: AppColors.white60, fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Stats Summary
                    Row(
                      children: [
                        _buildStatCard('${widget.totalCalories}', 'Calories'),
                        const SizedBox(width: 8),
                        _buildStatCard('${widget.totalProtein.toInt()}g', 'Protein'),
                        const SizedBox(width: 8),
                        _buildStatCard('${widget.totalFat.toInt()}g', 'Fat'),
                        const SizedBox(width: 8),
                        _buildStatCard('${widget.totalCarbs.toInt()}g', 'Carbs'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Items List
                    ...widget.items.map((item) => _buildItemCard(item)),
                  ],
                ),
              ),
            ),
            
            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => _saveLog(shouldPost: false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.white60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.pureWhite)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _saveLog(shouldPost: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Post Workout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLog({required bool shouldPost}) async {
    try {
      final foodsList = widget.items.map((item) {
        final isModified = item.foodId != null && (
          item.calories != item.originalCalories ||
          item.protein != item.originalProtein ||
          item.fat != item.originalFat || 
          item.carbs != item.originalCarbs
        );

        return {
          "foodId": item.foodId,
          "name": item.name,
          "calories": item.calories,
          "protein": item.protein,
          "fat": item.fat,
          "carbs": item.carbs,
          "quantity": item.quantity,
          "mealType": widget.mealType,
          "date": DateTime.now().toIso8601String(),
          "isModified": isModified
        };
      }).toList();

      final formData = FormData.fromMap({
        'foods': jsonEncode(foodsList),
        'mealType': widget.mealType,
        'date': DateTime.now().toIso8601String(),
        'caption': _captionController.text,
      });

      if (_selectedImages.isNotEmpty) {
        for (var image in _selectedImages) {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(image.path, filename: image.name),
          ));
        }
      }

      final response = await NutritionApiService().saveMeal(formData);

      if (!mounted) return;

      if (shouldPost) {
        try {
          final session = response['session'];
          if (session != null && session['id'] != null) {
            final sessionId = session['id'];
            await NutritionApiService().postMeal(sessionId);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved and Posted successfully!')),
              );
            }
          } else {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved, but could not post (Missing Session ID).')),
                );
             }
          }
        } catch (postError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved, but failed to post: $postError')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully!')),
        );
      }
      
      if (mounted) {
        Navigator.pop(context); // Pop Post Page
        Navigator.pop(context, true); // Pop Track Page
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTag(String text, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(DietLogItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
           Row(
             children: [
               Expanded(
                 child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greyDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(item.name.isEmpty ? 'Unknown' : item.name, style: const TextStyle(color: AppColors.pureWhite)),
                 ),
               ),
               const SizedBox(width: 12),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                 decoration: BoxDecoration(
                    color: AppColors.greyDark.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                 ),
                 child: Text('${item.quantity}', style: const TextStyle(color: AppColors.pureWhite)),
               )
             ],
           ),
           const SizedBox(height: 16),
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem('Calories', '${item.calories}Cal', AppColors.primary),
              _buildMacroItem('Protein', '${item.protein}g', AppColors.primary),
              _buildMacroItem('Fat', '${item.fat}g', AppColors.primary),
              _buildMacroItem('Carbs', '${item.carbs}g', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
     return Column(
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department, size: 12, color: color), 
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.greyDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: const TextStyle(color: AppColors.white60, fontSize: 12)),
        ),
      ],
    );
  }
}
