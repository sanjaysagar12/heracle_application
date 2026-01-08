import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../api/auth_service.dart';
import '../../../route.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedGoal;
  String? _originalUsername;
  
  bool _isLoading = true;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  Timer? _debounce;
  String? _name;

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
          _name = data['name'];
          _usernameController.text = data['username'] ?? '';
          _originalUsername = data['username'];
          _ageController.text = (data['age'] as int? ?? 0) <= 0 ? '' : data['age'].toString();
          _heightController.text = (data['height'] as num? ?? 0) <= 0 ? '' : data['height'].toString();
          _weightController.text = (data['weight'] as num? ?? 0) <= 0 ? '' : data['weight'].toString();
          
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
      print('Error fetching profile: $e');
      if (mounted) setState(() => _isLoading = false);
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
    
    // Don't check if user hasn't changed their username
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
    if (_formKey.currentState!.validate() && (_originalUsername == _usernameController.text || _isUsernameAvailable)) {
      try {
        setState(() => _isLoading = true);
        
        final data = {
          "username": _usernameController.text,
          "age": int.tryParse(_ageController.text) ?? 0,
          "height": double.tryParse(_heightController.text) ?? 0,
          "weight": double.tryParse(_weightController.text) ?? 0,
          "gender": _selectedGender ?? "MALE",
          "goal": _selectedGoal ?? "Hypertrophy"
        };
        
        await _authService.updateProfile(data);
        
        if (mounted) {
           Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _name == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Keep background stable, content will scroll or adjust
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image aligned to bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.6, // Occupy bottom 60%
            child: Image.asset(
              'assets/images/login_image.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Gradient Overlay: Black (Top) -> Transparent (Bottom) to blend image
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Header
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                              children: [
                                TextSpan(text: 'Welcome, ', style: TextStyle(color: AppColors.primary)),
                                TextSpan(text: _name ?? 'User'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Help us personalize your journey by sharing a bit about yourself. This takes just a moment.',
                            style: TextStyle(color: AppColors.white60, fontSize: 14),
                          ),
                          const SizedBox(height: 32),

                          // Inputs Grid
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  controller: _usernameController,
                                  hint: 'name', // Changed from 'username'
                                  onChanged: _onUsernameChanged,
                                  suffix: _isCheckingUsername 
                                      ? const SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(radius: 8, color: AppColors.primary)) 
                                      : _usernameController.text.isNotEmpty && _usernameController.text != _originalUsername
                                          ? Icon(_isUsernameAvailable ? Icons.check_circle : Icons.cancel, 
                                              color: _isUsernameAvailable ? AppColors.primary : Colors.red, size: 16)
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _ageController,
                                  hint: 'age',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(controller: _weightController, hint: 'weight (kg)', keyboardType: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(controller: _heightController, hint: 'height (cm)', keyboardType: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown(
                                  value: _selectedGender,
                                  hint: 'gender',
                                  items: _genders,
                                  onChanged: (val) => setState(() => _selectedGender = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDropdown(
                            value: _selectedGoal,
                            hint: 'what\'s your goal?',
                            items: _goals,
                            onChanged: (val) => setState(() => _selectedGoal = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Continue Button Pinned to Bottom
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading && _name != null) ? null : _submit, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: (_isLoading && _name != null)
                         ? const CircularProgressIndicator(color: Colors.black)
                         : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: AppColors.white40),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
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
        if (val == null || val.isEmpty) return '';
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.black100,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.white40),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: const TextStyle(color: AppColors.white40),
          floatingLabelStyle: const TextStyle(color: AppColors.primary),
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
    );
  }
}
