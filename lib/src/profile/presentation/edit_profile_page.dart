import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/api/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _selectedGender;
  String? _selectedGoal;
  String? _originalUsername;
  String? _currentProfileImageUrl;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  Timer? _debounce;
  File? _selectedImage;

  final List<String> _genders = ['MALE', 'FEMALE', 'OTHER'];
  final List<String> _goals = ['Hypertrophy', 'Strength', 'Endurance', 'Flexibility', 'Weight Loss'];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await _authService.getMyProfile();
      if (mounted) {
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _originalUsername = data['username'];
          _ageController.text = (data['age'] as int? ?? 0) <= 0 ? '' : data['age'].toString();
          _heightController.text = (data['height'] as num? ?? 0) <= 0 ? '' : data['height'].toString();
          _weightController.text = (data['weight'] as num? ?? 0) <= 0 ? '' : data['weight'].toString();
          _currentProfileImageUrl = data['profileImageUrl'];
          
          final gender = data['gender'] as String?;
          if (gender != null && _genders.contains(gender.toUpperCase())) {
            _selectedGender = gender.toUpperCase();
          }
          
          final goal = data['goal'] as String?;
          if (goal != null && _goals.contains(goal)) {
            _selectedGoal = goal;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (value.isEmpty) {
      setState(() {
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
      });
      return;
    }
    
    if (value == _originalUsername) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await _authService.checkUsernameAvailability(value);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = available;
          _isCheckingUsername = false;
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_formKey.currentState!.validate() && (_originalUsername == _usernameController.text || _isUsernameAvailable)) {
      try {
        setState(() => _isSaving = true);
        
        final data = {
          "username": _usernameController.text,
          "age": int.tryParse(_ageController.text) ?? 0,
          "height": double.tryParse(_heightController.text) ?? 0,
          "weight": double.tryParse(_weightController.text) ?? 0,
          "gender": _selectedGender ?? "MALE",
          "goal": _selectedGoal ?? "Hypertrophy"
        };
        
        await _authService.updateProfile(data, image: _selectedImage);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
           Navigator.pop(context, true); // Return true to refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving 
               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
               : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.greyDark,
                        shape: BoxShape.circle,
                        image: _selectedImage != null 
                             ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                             : (_currentProfileImageUrl != null 
                                 ? DecorationImage(image: NetworkImage(_currentProfileImageUrl!), fit: BoxFit.cover)
                                 : null),
                      ),
                      child: (_selectedImage == null && _currentProfileImageUrl == null) 
                          ? const Icon(Icons.person, size: 50, color: AppColors.white60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: AppColors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                controller: _usernameController,
                hint: 'Username',
                onChanged: _onUsernameChanged,
                suffix: _isCheckingUsername 
                    ? const SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(radius: 8, color: AppColors.primary)) 
                    : _usernameController.text.isNotEmpty && _usernameController.text != _originalUsername
                        ? Icon(_isUsernameAvailable ? Icons.check_circle : Icons.cancel, 
                            color: _isUsernameAvailable ? AppColors.primary : Colors.red, size: 16)
                        : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      hint: 'Age',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      value: _selectedGender,
                      hint: 'Gender',
                      items: _genders,
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField(controller: _heightController, hint: 'Height (cm)', keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller: _weightController, hint: 'Weight (kg)', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildDropdown(
                value: _selectedGoal,
                hint: 'Goal',
                items: _goals,
                onChanged: (val) => setState(() => _selectedGoal = val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(color: AppColors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.black100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(color: AppColors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButtonHideUnderline(
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.black100,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.white40),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.black100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: onChanged,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
