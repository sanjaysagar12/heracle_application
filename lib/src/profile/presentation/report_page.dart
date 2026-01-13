import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _messageController = TextEditingController();
  final Dio _dio = DioClient().dio; // Use centralized DioClient
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 2 images allowed')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, 
      );

      if (image != null) {
        final int sizeInBytes = await image.length();
        final double sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 10) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image size must be less than 10MB')),
            );
          }
          return;
        }
        
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue or attach an image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Prepare FormData
      // Backend expects 'issue' (text) and 'files' (file list)
      final formData = FormData.fromMap({
        "issue": message,
      });

      // Attach images
      if (_selectedImages.isNotEmpty) {
        for (var image in _selectedImages) {
          formData.files.add(MapEntry(
            "files", // Backend expects 'files' array/list
            await MultipartFile.fromFile(
              image.path,
              filename: image.name,
            ),
          ));
        }
      }

      // DioClient handles BaseURL and Auth Token
      final response = await _dio.post(
        '/api/email/report-bug',
        data: formData,
        options: Options(
          // Dio automatically sets multipart/form-data with boundary when data is FormData
        ),
      );

      // Close Loading Dialog
      if (!mounted) return;
      Navigator.pop(context); 
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        throw Exception('Failed to send report. Status: ${response.statusCode}');
      }

    } catch (e) {
      // Close Loading Dialog if error
      if (mounted && _isLoading) {
        Navigator.pop(context);
        setState(() => _isLoading = false);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 1.5,
            ),
             boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                "Report Sent",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Thank you for your feedback. We will look into it as soon as possible.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to settings
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            color: Colors.white,
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report a Problem',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'We are sorry to hear that.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tell us what happened and we will fix it as soon as possible.',
                    style: TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Text Input
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.greyDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.greyLight.withOpacity(0.3),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 6,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Describe the issue...',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Image Attachments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const Text(
                         "Attachments",
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                       Text(
                         "${_selectedImages.length}/2",
                         style: const TextStyle(color: Colors.grey),
                       ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Horizontal List of Images + Add Button
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add Button (Show only if < 2 images)
                        if (_selectedImages.length < 2)
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppColors.greyDark.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.greyLight.withOpacity(0.5),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                                  SizedBox(height: 4),
                                  Text(
                                    "Add Image",
                                    style: TextStyle(
                                      color: Colors.grey, 
                                      fontSize: 10
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Selected Images
                        ..._selectedImages.asMap().entries.map((entry) {
                           final index = entry.key;
                           final image = entry.value;
                           return Stack(
                             clipBehavior: Clip.none,
                             children: [
                               Container(
                                 width: 100,
                                 margin: const EdgeInsets.only(right: 12),
                                 decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(12),
                                   image: DecorationImage(
                                     image: FileImage(File(image.path)),
                                     fit: BoxFit.cover,
                                   ),
                                 ),
                               ),
                               Positioned(
                                 top: -8,
                                 right: 4,
                                 child: GestureDetector(
                                   onTap: () => _removeImage(index),
                                   child: Container(
                                     padding: const EdgeInsets.all(4),
                                     decoration: const BoxDecoration(
                                       color: Colors.red,
                                       shape: BoxShape.circle,
                                     ),
                                     child: const Icon(Icons.close, color: Colors.white, size: 14),
                                   ),
                                 ),
                               ),
                             ],
                           );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Max 2 images, 10MB each.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  const Spacer(),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Submit Report',
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
