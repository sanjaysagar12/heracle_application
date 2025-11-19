import 'package:flutter/material.dart';
import '../../../widgets/app_bar.dart';
import '../data/profile_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfileRepository _profileRepository = ProfileRepository();
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      print('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isLoading || _profile == null
          ? null
          : CustomAppBar(
              name: _profile!.name,
              age: _profile!.age,
              profileImageUrl: _profile!.profileImageUrl,
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : const Center(
              child: Text(
                "Home",
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}